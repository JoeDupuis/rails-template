class BaseGrid

  include Datagrid

  self.default_column_options = {
    # Uncomment to disable the default order
    # order: false,
    # Uncomment to make all columns HTML by default
    # html: true,
  }
  # Enable forbidden attributes protection
  # self.forbidden_attributes_protection = true

  attr_accessor :current_user


  def self.action_column  type, *args, **kwargs, &block

    #If no text is set as second arguments we set the type as the text for the link
    text = (args.first.kind_of?(String) || args.first.kind_of?(Symbol)) ? args.pop : type

    kwargs[:class] = (kwargs[:class] || '') + " action action--#{type}"

    policy = kwargs.delete(:policy_action)
    kwargs[:if] = ->(grid) { Pundit.policy!(grid.current_user, grid.policy).send(policy)} if policy

    column(:actions, header: '',  class: 'datagrid__action', html: true, if: kwargs.delete(:if)) do |model|
      link_to text, (block.present? ? block.call(model) : model), *args, **kwargs
    end
  end

  def self.date_column(name, *args)
    column(name, *args) do |model|
      format(block_given? ? yield : model.send(name)) do |date|
        date.strftime("%d/%m/%Y")
      end
    end
  end
end
