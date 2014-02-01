class Intervals

  def initialize(admin_user)
    @person_id = admin_user.intervals_person_id
    @token = admin_user.intervals_token
    @password = admin_user.intervals_secret
  end

  def url
    "https://#{@token}:#{@password}@api.myintervals.com/"
  end

  def retrieve_data
    data = RestClient.get "#{url}time?personid=#{@person_id}&limit=50&datebegin=#{last_month.first}&dateend=#{last_month.last}"
    time = JSON.parse(data)
  end

  def days_to_bill
    hours = retrieve_data['time'].map{|k,v| k['time'].to_i}
    (hours.sum / 8)
  end

  def last_month
    start_date = (Date.today - 1.month).beginning_of_month
    end_date = (Date.today - 1.month).end_of_month
    [start_date.to_s, end_date.to_s]
  end

end
