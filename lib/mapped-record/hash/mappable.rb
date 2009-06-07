class Hash
  # Returns a new Hash where the keys have been swapped with those defined in <tt>Mapping[named_mapping]</tt>.
  def map_with(named_mapping)
    if Mapping.has?(named_mapping)
      m = Mapping[named_mapping]

      result = self.inject({}) do |result, element|
        mapping = m[element.first]

        to = mapping[:to] if mapping
        proc = mapping[:filter] if mapping

        if to
          result[to] = element.last unless proc
          result[to] = proc.call(element.last) if proc
        end

        result
      end
    end
  end
end
