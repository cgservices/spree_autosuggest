class Spree::Suggestion < ActiveRecord::Base
  validates :keywords, :presence => true
  
  scope :has_data, where(["data is not ?", nil])

  def self.relevant(term)
    config = Spree::Autosuggest::Config

    select([:keywords, :data]).
      where("count >= ?", config.min_count).
      where("items_found != 0").
      where("keywords LIKE ? OR keywords LIKE ?", '%' + term + '%', '%' + KeySwitcher.switch(term) + '%').
      order("(#{config.count_weight}*count + #{config.items_found_weight}*items_found) DESC").
      limit(config.rows_from_db)
  end

end
