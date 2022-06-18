macro __marten_defined?(t)
  {% if t.resolve? %}
    {{ yield }}
  {% end %}
end
