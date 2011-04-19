class SimpleAdapter < SourceAdapter
  def initialize(source)
    super(source)
  end
 
  def login
    unless _is_empty?(current_user.login)
      true
    else
      raise SourceAdapterLoginException.new('Error logging in')
    end
  end
 
  def query(params=nil)
    @result
  end
  
  def search(params=nil,txt='')
    params[:foo] = 'bar' # this is for 'chaining' test
    if params['search'] == 'bar'
      @result = {'obj'=>{'foo'=>'bar'}} 
      # this is for 'chaining' test, addind 'iPhone' to trogger Sample adapter search result
      params['name'] = 'iPhone'  
    end
    @result
  end
 
  def sync
    super
  end
 
  def create(name_value_list,blob=nil)
    'obj4'
  end
  
  private
  def _is_empty?(str)
    str.length <= 0
  end
end