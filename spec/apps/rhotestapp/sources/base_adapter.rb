class BaseAdapter < SourceAdapter
  def initialize(source,credential)
    super(source,credential)
  end
 
  def query(params=nil)
    @result
  end
 
  def sync
    super
  end
end