module Opal::Sprockets::MimeTypes
  def register_mime_type(mime_type)
    mime_types << mime_type
  end

  def mime_types
    @mime_types ||= []
  end

  def sprockets_extnames_regexp(sprockets, opal_only: false)
    opal_extnames = sprockets.mime_types.map do |type, hash|
      hash[:extensions] if !opal_only || Opal::Sprockets.mime_types.include?(type)
    end.compact.flatten

    opal_extnames << ".js" unless opal_only

    Regexp.union(opal_extnames.map { |i| /#{Regexp.escape(i)}\z/ })
  end
end
