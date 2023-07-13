# frozen_string_literal: true

class Ability
  include CanCan::Ability

  def initialize(user)
    user ||= User.new # guest user (not logged in)
    puts "user.role.name ability ===> "+user.role.name.to_s
    case user.role.name
    when 'admin'
      can :manage, :all
    when 'manager'
      # can :read, :all
      can [:read, :update], Order
      cannot :download, Order
      can [:create, :update, :copy, :destroy], Kp
      can :autocomplete_product_title, Kp
      can [:print1, :print2, :print3, :print4], Kp
      can [:file_import, :file_export], Kp
      can [:update_modal], KpProduct
      can :manage, KpProduct
      can :manage, Product
      cannot :insales_import, Product
      can :manage, Client
      can :manage, Company
    when 'grand_manager'
      can [:read, :update], Order
      cannot :download, Order
      can [:create, :update, :copy, :destroy], Kp
      can :autocomplete_product_title, Kp
      can [:print1, :print2, :print3, :print4], Kp
      can [:file_import, :file_export], Kp
      can :manage, Product
      cannot :insales_import, Product
      can :manage, Client
      can :manage, Company
    when 'operator'
      can [:read, :update], Order
      cannot :download, Order
      cannot :create, Kp
      cannot :copy, Kp
    when 'bookkeeper'
      can [:index,:read,:update], Order
      cannot :download, Order
      can :index_all, Kp
      can :update, Kp
      can [:print1c, :print1, :print2, :print3, :print4], Kp
      cannot :create, Kp
      cannot :copy, Kp
    else
      # user not signed in should view a sign_up page:
      can :read, :sign_up
    end
  end

  # def initialize(user)

  # read: [:index, :show]
  # create: [:new, :create]
  # update: [:edit, :update]
  # destroy: [:destroy]
  #   # Define abilities for the passed in user here. For example:
  #   #
  #   #   user ||= User.new # guest user (not logged in)
  #   #   if user.admin?
  #   #     can :manage, :all
  #   #   else
  #   #     can :read, :all
  #   #   end
  #   #
  #   # The first argument to `can` is the action you are giving the user
  #   # permission to do.
  #   # If you pass :manage it will apply to every action. Other common actions
  #   # here are :read, :create, :update and :destroy.
  #   #
  #   # The second argument is the resource the user can perform the action on.
  #   # If you pass :all it will apply to every resource. Otherwise pass a Ruby
  #   # class of the resource.
  #   #
  #   # The third argument is an optional hash of conditions to further filter the
  #   # objects.
  #   # For example, here the user can only update published articles.
  #   #
  #   #   can :update, Article, :published => true
  #   #
  #   # See the wiki for details:
  #   # https://github.com/CanCanCommunity/cancancan/wiki/Defining-Abilities
  # end
end
