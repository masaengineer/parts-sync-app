class StaticPagesController < ApplicationController
  skip_before_action :authenticate_user!
  layout 'landing', only: [:landing]

  def privacy_policy
  end

  def terms_of_service
  end

  def scta
  end

  def landing
  end
end
