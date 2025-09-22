require "ostruct"

class ApplicationService
  def self.call(*args, **kwargs, &block)
    new(*args, **kwargs).call(&block)
  end

  def call
    # To be implemented by child classes
    raise NotImplementedError, "#{self.class}#call is not implemented"
  end

  private

  def success(data = {})
    OpenStruct.new(success?: true, data:, error: nil)
  end

  def failure(error)
    OpenStruct.new(success?: false, data: nil, error:)
  end
end
