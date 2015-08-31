module Spree
  class SuggestionsController < Spree::StoreController
    caches_action :index, cache_path: Proc.new {|c| c.request.url }

    def index
      params['term'] ||= ' '
      port = Rails.env == 'development' ? ':3000' : ''
      if Spree::Autosuggest::Config[:search_backend]
        suggestions = Spree::Config[:searcher_class].new(keywords: params['term']).retrieve_products
        suggestions = Spree::Product.search(name_cont: params['term']).result(distinct: true) if suggestions.blank?
        suggestions.collect!{|p|
          image = p.andand.images.andand.first || p.andand.variants.andand.collect(&:images).flatten.first
          {
            keywords: p.name,
            url: p.permalink.present ? p.permalink : "",
            store_url: defined?(current_store) && current_store != p.andand.stores.andand.first ? "http://#{p.andand.stores.andand.first.andand.domains.split(",").first}#{port}" : '',
            store_name: p.respond_to?(:stores) ? p.stores.first.code : '',
            store_identifier: p.respond_to?(:stores) ? p.stores.first.code : '',
            product_id: p.id,
            product_name: p.name,
            suggestion_type: 'products',
            image_url: image.present? ? image.mini_url : '',
            price: p.respond_to?(:stores) ? p.master.price(p.stores.first) : p.master.price,
          }
        }
      else
        group = defined?(current_store) && current_store.respond_to?(:group) ? current_store.group : nil
        suggestions = Spree::Suggestion.relevant(params['term'], group).
                      joins('LEFT JOIN spree_products ON (spree_products.id = spree_suggestions.product_id)').
                      joins('LEFT JOIN spree_variants ON (spree_variants.product_id = spree_products.id AND spree_variants.is_master = 1)')
        suggestions.collect!{|s|
          image = s.product.andand.images.andand.first || s.product.andand.variants.andand.collect(&:images).andand.flatten.andand.first
          {
            keywords: s.keywords,
            url: s.data.present? && eval(s.data).has_key?(:url) ? eval(s.data)[:url] : '',
            store_url: s.respond_to?(:store_id) && current_store.id != s.store_id ? "http://#{Spree::Store.find_by_id(s.store_id).domains.split(",").first}#{port}"  : '',
            store_name: s.data.present? && eval(s.data).has_key?(:store_name) ? eval(s.data)[:store_name] : '',
            store_identifier: s.data.present? && eval(s.data).has_key?(:store_name) ? Spree.t(eval(s.data)[:store_name], :scope => [:auto_suggest]) : '',
            product_id: s.product_id,
            product_name: s.andand.product.present? ? s.product.name : s.keywords,
            suggestion_type: s.data.present? && eval(s.data).has_key?(:suggestion_type) ? eval(s.data)[:suggestion_type] : '',
            image_url: image.present? ? image.mini_url : '',
            price: s.andand.product.andand.master.present? ? Spree::Money.new(s.product.master.price(Spree::Store.find_by_id(s.store_id)), { :currency => s.product.master.currency}).to_s : ''
          }
        }
      end

      if request.xhr?
        render json: suggestions
      else
        render_404
      end
    end
  end
end
