macro defined?(t)
  {% if t.resolve? %}
    {{ yield }}
  {% end %}
end
