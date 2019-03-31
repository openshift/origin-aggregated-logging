require 'ffi'

# @private
class FFI::MemoryPointer
  # monkey patch a read_size_t and write_size_t method onto FFI::MemoryPointer.
  # see https://github.com/ffi/ffi/issues/118
  def self.monkey_patch_type_i_need!(which)
    return if self.respond_to?("read_#{which}")

    type = FFI.find_type(which)
    type, _ = FFI::TypeDefs.find do |(name, t)|
      method_defined?("read_#{name}") if t == type
    end

    raise "Unable to patch in reader/writer for #{which}" if type.nil?

    alias_method "read_#{which}", "read_#{type}"
    alias_method "write_#{which}", "write_#{type}"
  end
end

[:size_t, :uint64, :uint32].each do |type|
  FFI::MemoryPointer.monkey_patch_type_i_need!(type)
end
