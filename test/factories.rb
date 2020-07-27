require 'factory_girl'

FactoryGirl.define do

  factory :post do
    sequence(:title) {|n| "Fake Post #{n}"}
    body ""

    factory :published_post do
      self.private false
      draft false
    end

    factory :draft_post do
      self.private false
      draft true
    end
  end

end