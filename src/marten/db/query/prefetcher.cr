module Marten
  module DB
    module Query
      # The main prefetcher class.
      #
      # A prefetcher is responsible for prefetching relation recordss for the records matched by a given query set. This
      # allows to avoid N+1 queries problems for relation fields (and reverse relations) that map to multiple records.
      #
      # A prefetcher is initialized with an array of records, an array of relation strings to prefetch, and an the
      # identifier of the database to use for the prefetching queries. The prefetcher decorates the records with the
      # prefetched records, and also caches the prefetched records for future use.
      class Prefetcher
        def initialize(@records : Array(Model), @relations : Array(String), @using : String?)
        end

        def execute : Nil
          already_prefetched_relations = {} of String => Array(Model)

          remaining_prefetched_relations = relations.reverse

          while !remaining_prefetched_relations.empty?
            relation = remaining_prefetched_relations.pop
            next if already_prefetched_relations.has_key?(relation)

            records_to_possibly_decorate = Array(Model).new + records

            traversed_relations = relation.split(Constants::LOOKUP_SEP)
            accumulated_traversed_relation = ""
            traversed_relations.each do |traversed_relation|
              # Construct the accumulated traversed relation string. This will be used as a key to cache the prefetched
              # records for the traversed relation (so that we don't have to fetch them again if we encounter the same
              # relation later on).
              accumulated_traversed_relation += if accumulated_traversed_relation.empty?
                                                  traversed_relation
                                                else
                                                  Constants::LOOKUP_SEP + traversed_relation
                                                end

              # Skip to the next relation to prefetch if there are no records for which to prefetch the relation.
              break if records_to_possibly_decorate.empty?

              # Skip to the next relation to prefetch if the prefetched records for the accumulated traversed relation
              # were already fetched.
              if already_prefetched_relations.has_key?(accumulated_traversed_relation)
                records_to_possibly_decorate = already_prefetched_relations[accumulated_traversed_relation]
                next
              end

              # STEP 1: Initialize the prefetched records cache for the records that should be possibly decorated.

              records_to_possibly_decorate.each do |record|
                record.initialize_prefetched_records_cache unless record.prefetched_records_cache_initialized?
              end

              # STEP 2: Fetch the traversed relation context (which can be for a regular field or a reverse relation).

              first_record = records_to_possibly_decorate.first
              traversed_relation_context = begin
                first_record.class.get_relation_field_context(traversed_relation)
              rescue Errors::UnknownField
                first_record.class.get_reverse_relation_context(traversed_relation)
              end

              # STEP 3: Identify the records that should be decorated with prefetched records.

              records_to_decorate = if traversed_relation_context.is_a?(DB::Model::Table::FieldContext)
                                      get_records_to_decorate_from_field_context(
                                        traversed_relation,
                                        traversed_relation_context,
                                        records_to_possibly_decorate,
                                      )
                                    elsif traversed_relation_context.is_a?(DB::Model::Table::ReverseRelationContext)
                                      get_records_to_decorate_from_reverse_relation_context(
                                        traversed_relation,
                                        traversed_relation_context,
                                        records_to_possibly_decorate,
                                      )
                                    else
                                      raise Errors::InvalidField.new(
                                        "Cannot find '#{traversed_relation}' relation on #{first_record.class.name} " \
                                        "record, '#{traversed_relation}' is not a relation that can be prefetched"
                                      )
                                    end

              # STEP 4: Fetch the prefetched records and decorate the records with them.

              if records_to_decorate.empty?
                # No records to decorate can indicate that these records were already "prefetched" using other ways (for
                # example, using #join). If this is the case, we should just skip to the next relation to prefetch.

                new_records_to_possibly_decorate = Array(Model).new
                records_to_possibly_decorate.each do |record|
                  if record.prefetched_records_cache.includes?(traversed_relation)
                    new_records_to_possibly_decorate += record.prefetched_records_cache[traversed_relation]
                  elsif traversed_relation_context.is_a?(DB::Model::Table::ReverseRelationContext)
                    if !(prefetched_record = record.get_reverse_related_object_variable(traversed_relation)).nil?
                      new_records_to_possibly_decorate << prefetched_record
                    end
                  else
                    if !(prefetched_record = record.get_related_object_variable(traversed_relation)).nil?
                      new_records_to_possibly_decorate << prefetched_record
                    end
                  end
                end

                records_to_possibly_decorate = new_records_to_possibly_decorate
              else
                prefetched_records = if traversed_relation_context.is_a?(DB::Model::Table::FieldContext)
                                       prefetch_relation_records_from_field_context(
                                         traversed_relation,
                                         traversed_relation_context,
                                         records_to_decorate,
                                       )
                                     else
                                       prefetch_relation_records_from_reverse_relation_context(
                                         traversed_relation,
                                         traversed_relation_context,
                                         records_to_decorate,
                                       )
                                     end

                already_prefetched_relations[accumulated_traversed_relation] = prefetched_records
                records_to_possibly_decorate = prefetched_records
              end
            end
          end
        end

        private getter records
        private getter relations
        private getter using

        private def get_records_to_decorate_from_field_context(
          relation_name : String,
          context : Model::Table::FieldContext,
          records_to_possibly_decorate : Array(Model),
        ) : Array(Model)
          records_to_decorate = Array(Model).new

          if context.field.is_a?(Field::ManyToOne) || context.field.is_a?(Field::OneToOne)
            records_to_decorate += records_to_possibly_decorate
              .reject { |r| r.related_object_assigned?(context.field.relation_name) }
          elsif context.field.is_a?(Field::ManyToMany)
            records_to_decorate += records_to_possibly_decorate
              .reject { |r| r.prefetched_records_cache.has_key?(relation_name) }
          end

          records_to_decorate
        end

        private def get_records_to_decorate_from_reverse_relation_context(
          relation_name : String,
          context : Model::Table::ReverseRelationContext,
          records_to_possibly_decorate : Array(Model),
        ) : Array(Model)
          records_to_decorate = Array(Model).new

          if context.reverse_relation.one_to_one?
            records_to_decorate += records_to_possibly_decorate
              .reject { |r| r.reverse_related_object_assigned?(context.reverse_relation.id) }
          else
            records_to_decorate += records_to_possibly_decorate
              .reject { |r| r.prefetched_records_cache.has_key?(relation_name) }
          end

          records_to_decorate
        end

        private def prefetch_relation_records_from_field_context(
          relation_name : String,
          context : Model::Table::FieldContext,
          records_to_decorate : Array(Model),
        ) : Array(Model)
          prefetched_records = Array(Model).new

          if context.field.is_a?(Field::ManyToOne) || context.field.is_a?(Field::OneToOne)
            prefetched_records_pks = records_to_decorate.compact_map(&.get_field_value(context.field.id))
            return prefetched_records if prefetched_records_pks.empty?

            prefetched_records.concat(
              context.field.related_model
                .unscoped
                .using(using)
                .filter(pk__in: prefetched_records_pks)
                .query
                .execute
            )
            prefetched_records_by_pk = prefetched_records.index_by(&.pk)

            records_to_decorate.each do |record_to_decorate|
              next if !prefetched_records_by_pk.has_key?(record_to_decorate.get_field_value(context.field.id))

              record_to_decorate.assign_related_object(
                prefetched_records_by_pk[record_to_decorate.get_field_value(context.field.id)],
                context.field.id,
              )
            end
          elsif (m2m_field = context.field).is_a?(Field::ManyToMany)
            prefetched_records.concat(
              prefetch_m2m_relation_records(
                relation_name,
                m2m_field,
                records_to_decorate,
                context.field.related_model,
                true,
              )
            )
          end

          prefetched_records
        end

        private def prefetch_relation_records_from_reverse_relation_context(
          relation_name : String,
          context : Model::Table::ReverseRelationContext,
          records_to_decorate : Array(Model),
        ) : Array(Model)
          prefetched_records = Array(Model).new

          if context.reverse_relation.one_to_one?
            prefetched_records.concat(
              context.reverse_relation.model
                .unscoped
                .using(using)
                .filter(Node.new({"#{context.reverse_relation.field.id}__in" => records_to_decorate.map(&.pk)}))
                .query
                .execute
            )

            prefetched_records_by_related_object_pk = prefetched_records.index_by do |r|
              r.get_field_value(context.reverse_relation.field.id)
            end

            records_to_decorate.each do |record_to_decorate|
              next if !prefetched_records_by_related_object_pk.has_key?(record_to_decorate.pk)

              record_to_decorate.assign_reverse_related_object(
                prefetched_records_by_related_object_pk[record_to_decorate.pk],
                context.reverse_relation.id,
              )
            end
          elsif context.reverse_relation.many_to_one?
            prefetched_records.concat(
              context.reverse_relation.model
                .unscoped
                .using(using)
                .filter(Node.new({"#{context.reverse_relation.field.id}__in" => records_to_decorate.map(&.pk)}))
                .query
                .execute
            )

            records_to_decorate.each do |record_to_decorate|
              record_to_decorate.prefetched_records_cache[relation_name] = Array(Model).new
              record_to_decorate.prefetched_records_cache[relation_name].concat(
                prefetched_records.select do |r|
                  r.get_field_value(context.reverse_relation.field.id) == record_to_decorate.pk
                end
              )

              qs = record_to_decorate.get_reverse_related_queryset(relation_name)
              qs.assign_cached_records(record_to_decorate.prefetched_records_cache[relation_name])
            end
          elsif context.reverse_relation.many_to_many?
            m2m_field = context.reverse_relation.field.as(Field::ManyToMany)

            prefetched_records.concat(
              prefetch_m2m_relation_records(
                relation_name,
                m2m_field,
                records_to_decorate,
                context.reverse_relation.model,
                false,
              )
            )
          end

          prefetched_records
        end

        private def prefetch_m2m_relation_records(
          relation_name : String,
          m2m_field : Field::ManyToMany,
          records_to_decorate : Array(Model),
          prefetched_model : Model.class,
          forward : Bool,
        ) : Array(Model)
          # Retrieve the through records in order to get the related records.
          # TODO: Fetch everything in a single query when support for annotations is added.
          m2m_through_from_field = m2m_field.through.get_local_relation_field(m2m_field.through_from_field_id)
          m2m_through_to_field = m2m_field.through.get_local_relation_field(m2m_field.through_to_field_id)
          through_records = m2m_field.through.unscoped.using(using).filter(
            if forward
              Node.new({"#{m2m_through_from_field.id}__in" => records_to_decorate.map(&.pk)})
            else
              Node.new({"#{m2m_through_to_field.id}__in" => records_to_decorate.map(&.pk)})
            end
          ).query.execute

          # Query for the prefetched records by using the through records.
          related_record_ids = through_records.each_with_object(Array(Field::Any).new) do |x, acc|
            acc << x.get_field_value(forward ? m2m_through_to_field.id : m2m_through_from_field.id)
          end.compact

          prefetched_records = Array(Model).new
          prefetched_records.concat(
            prefetched_model.unscoped.using(using).filter(pk__in: related_record_ids).query.execute
          )

          through_record_join_pks = through_records.map do |through_record|
            [
              through_record.get_field_value(m2m_through_from_field.id),
              through_record.get_field_value(m2m_through_to_field.id),
            ].join("_")
          end.to_set

          # Decorate the records with the prefetched records.
          records_to_decorate.each do |record_to_decorate|
            record_to_decorate.prefetched_records_cache[relation_name] = Array(Model).new
            record_to_decorate.prefetched_records_cache[relation_name].concat(
              prefetched_records.select do |prefetched_record|
                through_record_join_pks.includes?(
                  if forward
                    [record_to_decorate.pk, prefetched_record.pk].join("_")
                  else
                    [prefetched_record.pk, record_to_decorate.pk].join("_")
                  end
                )
              end
            )

            qs = if forward
                   record_to_decorate.get_related_queryset(relation_name)
                 else
                   record_to_decorate.get_reverse_related_queryset(relation_name)
                 end

            qs.assign_cached_records(record_to_decorate.prefetched_records_cache[relation_name])
          end

          prefetched_records
        end
      end
    end
  end
end
