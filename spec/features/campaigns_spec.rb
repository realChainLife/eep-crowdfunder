require 'rails_helper'

describe 'campaigns' do

  before :each do
    @campaign = FactoryBot.create :campaign,
      title: 'Spec Campaign',
      start_date: 100.days.from_now,
      end_date: 200.days.from_now

    @goody = FactoryBot.create :goody, title: 'Spec Goody', campaign: @campaign
  end

  feature 'campaigns#show' do

    scenario 'renders' do
      visit campaign_path(@campaign)
      expect(page).to have_content 'Spec Campaign'
    end

    scenario 'has a slugged url' do
      visit campaign_path(@campaign)
      expect(current_path).to include('spec-campaign')
    end

  end

  feature 'date based logic' do

    scenario 'before the campaign starts' do
      visit campaign_path(@campaign)
      expect(page).to have_content "Noch 3 Monate bis zum Start!"
      expect(page).to have_css ".qa-time_until_start"
    end

    scenario 'while the campaign runs' do
      Timecop.freeze(Date.today + 100) do
        visit campaign_path(@campaign)
        expect(page).to_not have_css ".qa-time_until_start"
      end
    end

  end


  scenario 'navigation to the goodies' do
    visit campaign_path(@campaign)
    find('.qa-support-project').click
    expect(page).to have_content 'Spec Goody'
  end

  feature 'buying goodies' do

    scenario 'confirmation page' do
      visit campaign_goodies_path([@campaign])
      find('.qa-pledge').click
      # Text from @campaign.order_description
      expect(page).to have_content("How to buy")
      expect(page).to have_content I18n.t('orders.new.confirmation')
    end

    scenario 'not without a agreement' do
      visit campaign_goodies_path([@campaign])
      find('.qa-pledge').click
      find('.qa-submit').click
      expect(page).to have_content I18n.t('errors.messages.blank')
    end

    scenario 'not without nested supporter info' do
      visit campaign_goodies_path([@campaign])
      find('.qa-pledge').click
      find('.qa-agreement').click
      find('.qa-submit').click
      expect(page).to have_content I18n.t('errors.messages.blank')
    end

    scenario 'with agreement and all fields filled out' do
      expect do
        visit campaign_goodies_path([@campaign])
        find('.qa-pledge').click

        fill_in I18n.t('orders.new.first_name'), with: "John"
        fill_in I18n.t('orders.new.last_name'), with: "Doe"
        fill_in I18n.t('orders.new.email'), with: "supporter@example.com"
        fill_in I18n.t('orders.new.street'), with: "Spec Street"
        fill_in I18n.t('orders.new.postal_code'), with: "12345"
        fill_in I18n.t('orders.new.city'), with: "Glarus"
        select "Schweiz", from: I18n.t('orders.new.country')
        select "1950", from: "order_supporter_attributes_date_of_birth_1i"
        find('.qa-agreement').click
        find('.qa-submit').click
        expect(page).to_not have_content I18n.t('errors.messages.blank')
      end.to change{Order.count}.from(0).to(1)
    end
  end


  describe "FriendlyId" do

    it 'works on newly created resources' do
      campaign = FactoryBot.create :campaign, title: 'spec title'
      expect(campaign.slug).to eq('spec-title')
      expect(campaign_path(campaign)).to include('spec-title')
    end

    it 'when changing the title, the old and new slugs work' do
      campaign = FactoryBot.create :campaign, title: 'spec title'
      expect(campaign.slug).to eq('spec-title')
      expect(campaign_path(campaign)).to include('spec-title')

      campaign.update_attribute :title, 'some new title'
      expect(campaign.slug).to eq('spec-title')
      expect(campaign_path(campaign)).to include('spec-title')

      visit '/campaigns/spec-title'
      expect(page.status_code).to be(200)
      expect(current_path).to eq(campaign_path(campaign))

      visit '/campaigns/some-new-title'
      expect(page.status_code).to be(200)
      expect(current_path).to eq('/campaigns/some-new-title')
    end
  end

end
