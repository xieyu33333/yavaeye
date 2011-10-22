class Hash
  BOOLEAN_ATTRIBUTES = %w[disabled readonly multiple checked autobuffer
                       autoplay controls loop selected hidden scoped async
                       defer reversed ismap seemless muted required
                       autofocus novalidate formnovalidate open].to_set
  BOOLEAN_ATTRIBUTES.merge(BOOLEAN_ATTRIBUTES.map &:to_sym)
  
  def to_attrs
    r = []
    each_pair do |key, value|
      if BOOLEAN_ATTRIBUTES.include?(key)
        r << %(#{key}="#{key}") if value
      elsif !value.nil?
        value =
          case value
          when String; value.inspect
          when Array, Hash; value.inspect.inspect
          else value.to_s.inspect
          end
        r << "#{key}=#{value}"
      end
    end
    r.sort!
    r * ' '
  end
end