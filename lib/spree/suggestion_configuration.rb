class Spree::SuggestionConfiguration < Spree::Preferences::Configuration
  preference :rows_to_display,    :integer, :default => 10
  preference :rows_from_db,       :integer, :default => 45
  preference :count_weight,       :integer, :default => 2
  preference :items_found_weight, :integer, :default => 1
  preference :min_count,          :integer, :default => 5
  preference :field,              :string,  :default => 'keywords'
end
