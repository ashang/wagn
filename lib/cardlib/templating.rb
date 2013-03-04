module Cardlib::Templating

  def template?
    cardname.trait_name? :content, :default
  end
  
  def is_hard_template?
    cardname.trait_name? :content
  end

  def template
    # currently applicable templating card.
    # note that a *default template is never returned for an existing card.
    @template ||= begin
      @virtual = false
      if new_card?
        default_card = rule_card :default, :skip_modules=>true

        dup_card = self.dup
#        dup_card.type_id_without_tracking = default_card.type_id
        dup_card.type_id_without_tracking = default_card ? default_card.type_id : Card::DefaultTypeID


        if content_card = dup_card.content_rule_card
          @virtual = true
          content_card
        else
          default_card
        end
      elsif tmpl = content_rule_card
        if type_id != tmpl.type_id and tmpl.assigns_type?
          repair_type tmpl.type_id
        end
        tmpl
      end
    end
  end

  def hard_template
    if template && template.is_hard_template?
      template
    end
  end

  def virtual?
    return false unless new_card?
    if @virtual.nil?
      cardname.simple? ? @virtual=false : template
    end
    @virtual
  end

  def content_rule_card
    card = rule_card :content, :skip_modules=>true
    card && card.content.strip == '_self' ? nil : card
  end

  def hard_templatee_names
    if wql = hard_templatee_spec
      #warn "ht_names_wql #{wql.inspect}"
      Account.as_bot do
        wql == true ? [name] : Wql.new(wql.merge :return=>:name).run
      end
    else [] end
  end

  # FIXME: content settings -- do we really need the reference expiration system?
  #
  # I kind of think so.  otherwise how do we handled patterned references in hard-templated cards?
  # I'll leave the FIXME here until the need is well documented.  -efm

  def expire_templatee_references
    if query = hard_templatee_spec
      Account.as_bot do
        query = {:name => name} if query == true
        Wql.new( query.merge(:return => :id) ).run.each_slice(100) do |id_batch|
          Card.where( :id => id_batch ).update_all :references_expired=>1
        end
      end
    end
  end


  def assigns_type?
    if is_hard_template?
      set_class = Cardlib::Pattern.find_class cardname.trunk_name
      set_class && set_class.assigns_type
    end
  end

  private
  
  def repair_type template_type_id
    self.type_id = template_type_id
    update_column :type_id, type_id
    reset_patterns
  end

  def hard_templatee_spec
    if is_hard_template? and c=Card.fetch(cardname.trunk_name)
      c.type_id == Card::SetID ? c.get_spec : true
    end
  end
  


end
