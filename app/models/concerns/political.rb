module Political
  extend ActiveSupport::Concern
  # included do
  # end

  module ClassMethods
    def sqlize_array(arr)
      "('" + arr.join("','") + "')"
    end
    
    # Array -> String
    def name_query_string(names)
      query = " (name_first = ? and name_last = ?) "
      if names.length == 1
        query
      else
        ( [ query ] * names.length ).join("OR")
      end
    end

  end
  
  def contribids
    contributions.pluck(:contribid).uniq
  end

  def aliases_names
    aliases.map { |a| NameParser.parse_to_hash(a.name) }
  end 
 
  def potential_contributions
    names = aliases_names
    return [] unless names.length > 0
    ids = contribids

    before_query = "SELECT potential.* FROM ( "
    base_query = "SELECT * FROM os_donations WHERE" + Entity.name_query_string(names)
    after_query = ") as potential LEFT JOIN os_matches on potential.id = os_matches.os_donation_id where os_matches.os_donation_id is null"
    (base_query += " OR ( contribid IN #{self.class.sqlize_array(ids)} )") if not ids.empty?
    
    OsDonation.find_by_sql([ "#{before_query}#{base_query}#{after_query}" ] + names.map { |name| [ name[:name_first], name[:name_last] ] }.flatten)
  end

  def contribution_info
    query = "SELECT os_matches.id as os_match_id, 
                    os_donations.*, 
                    entity.id as recip_id,
                    entity.name as recip_name,
                    entity.blurb as recip_blurb,
                    entity.primary_ext as recip_ext
             FROM os_matches 
             LEFT JOIN os_donations on os_matches.os_donation_id = os_donations.id 
             LEFT JOIN entity on os_matches.recip_id = entity.id
             WHERE os_matches.donor_id = ?"
    OsMatch.find_by_sql [ query, self.id ]
  end
end
