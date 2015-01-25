require 'factory_girl'

FactoryGirl.define do

  factory :post do
    sequence(:title) {|n| "Fake Post #{n}"}

    factory :published_post do
      self.private false
      draft false
    end

    factory :draft_post do
      self.private false
      draft true
    end
  end

  factory :comment do
    email "fake-user@example.com"
  end

end