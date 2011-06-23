module Card::Role
  include Card::Basic
  
  def before_validation_on_create
    create_extension
  end
  
  def create_extension
    self.extension = ::Role.create( :codename => name )
  end
  
  private
      
  def on_type_change
    destroy_extension
  end
end
