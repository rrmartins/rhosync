module Document
  
  # Store wrapper methods for document
  def get_data(doctype,type=Hash)
    Store.get_data(docname(doctype),type)
  end
  
  def get_value(doctype)
    Store.get_value(docname(doctype))
  end
  
  def put_data(doctype,data,append=false)
    Store.put_data(docname(doctype),data,append)
  end
  
  def put_value(doctype,data)
    Store.put_value(docname(doctype),data)
  end
  
  def delete_data(doctype,data)
    Store.delete_data(docname(doctype),data)
  end
  
  def flash_data(doctype)
    Store.flash_data(docname(doctype))
  end
  
  # Generate the fully-qualified docname
  def docname(doctype)
    "#{self.class.class_prefix(self.class)}:#{self.app_id}:#{self.user_id}:#{self.doc_suffix(doctype)}"
  end
  
  # Update count for a given document
  def update_count(doctype,count)
    name = docname(doctype)
    value = Store.db.get(name).to_i + count
    Store.db.set(name,value < 0 ? 0 : value) 
  end
end