class InvoicePdf < Prawn::Document
  include ActionView::Helpers::NumberHelper

  def initialize(invoice, time = [])
    super()
    @invoice = invoice
    invoice_content
    return unless time.any?
    start_new_page
    add_time(time)
  end

  def add_time(time)
    text "Timesheet for #{@invoice.client.organization.name}", :size => 14, :style => :bold
    move_down 10
    timesheet_data = []
    timesheet_data << ["Date", "Project", "Task Description", "Hours"]

    total_hours = 0
    time.each do |item|
      total_hours += item[:hours]
      timesheet_data << [item[:date].strftime('%d %b %y'), item[:project], item[:description], "#{item[:hours]}:00"]
    end

    timesheet_data << ['','','Total', "#{total_hours}:00"]

    table(timesheet_data, :width => bounds.width, :row_colors => ["FFFFFF", "f4f4f4"]) do
      style(row(0..-1).columns(0..-1), :borders => [:bottom], :border_color => 'dddddd')
      style(row(0), :background_color => '000000', :border_color => 'dddddd', :font_style => :bold, :text_color => 'ffffff')
      style(column(-1), :align => :right)
      style(row(-1), :border_width => 2,:align => :right, :font_style => :bold, :size => 14)
    end
  end

  def invoice_content
    organization = @invoice.client.organization
    font_size 10
    bounding_box([350, 690], :width => 200, :height => 100) do
      text organization.name, :style => :bold
      move_down 1
      [
        organization.street_1,
        organization.street_2,
        organization.city,
        organization.zip_code
      ].each do |line|
        text line
        move_down 1
      end
    end

    # Client info
    bounding_box([0, 600], :width => 250, :height => 100) do
      horizontal_rule
      move_down 10
      text @invoice.client.name, :style => :bold
      @invoice.client.address.split(',').each do |line|
        text line
      end
      text @invoice.client.phone
    end

    # Invoice number and due date
    bounding_box([350, 600], :width => 200, :height => 100) do
      horizontal_rule
      move_down 10
      text "INVOICE #{@invoice.code.to_s.rjust(3, '0')}", :size => 14, :style => :bold
      move_down 1
      text I18n.l(@invoice.created_at, :format => :pdf), :size => 12, :style => :bold
      move_down 1
      due = @invoice.due_date.blank? ? "on receipt" : I18n.l(@invoice.due_date, :format => :pdf)
      text "Payment Due by #{due}", :size => 10, :style => :bold, :color => "999999"
    end

    # Client info
    move_down 20

    # Items
    invoice_services_data = []
    invoice_services_data << ["Quantity", "Details", "Unit Price", "VAT", "Net Subtotal"]

    @invoice.items.collect do |item|
      invoice_services_data << [item.quantity.to_s + " Days", item.description, number_to_currency(item.amount), number_to_percentage(item.tax, :strip_insignificant_zeros => true), number_to_currency(item.total)]
    end

    invoice_services_data << [" ", " ", " ", " ", " "]

    table(invoice_services_data, :width => bounds.width) do
      style(row(1..-1).columns(0..-1), :padding => [4, 5, 4, 5], :borders => [:bottom], :border_color => 'dddddd')
      style(row(1), :background_color => 'f4f4f4')
      style(row(0), :background_color => '000000', :border_color => 'dddddd', :font_style => :bold, :text_color => 'ffffff')
      style(row(0).columns(0..-1), :borders => [:top, :bottom])
      style(row(0).columns(0), :borders => [:top, :left, :bottom])
      style(row(0).columns(-1), :borders => [:top, :right, :bottom])
      style(row(-1), :border_width => 2)
      style(column(2..-1), :align => :right)
      style(columns(0), :width => 75)
      style(columns(1), :width => 275)
    end

    move_down 1

    # Item totals
    invoice_services_totals_data = [
      ["Net Total", number_to_currency(@invoice.subtotal)],
      ["VAT", number_to_currency(@invoice.taxes)],
      ["GBP Total", number_to_currency(@invoice.total)]
    ]

    table(invoice_services_totals_data, :position => :right, :width => bounds.width) do
      style(row(0..2).columns(1), :width => 75 )
      style(column(0..1), :align => :right, :border_color => 'dddddd', :borders => [:top])
      style(row(2), :font_style => :bold, :size => 12)
    end

    # Bank details
    bounding_box([0, 300], :width => 200, :height => 100) do
      text "Payment details", :style => :bold, :size => 11
      move_down 10
      [organization.bank_name,
      "Bank/Sort Code: #{organization.sort_code}",
      "Account Number: #{organization.account_number}",
      "Payment Reference: #{@invoice.code}"].each do |line|
        text line
        move_down 1
      end
    end

    # Company details
    bounding_box([350, 300], :width => 200, :height => 100) do
      text "Other Information", :style => :bold, :size => 11
      move_down 10
      text  "VAT Number: #{organization.vat_number}"
      text  "Company Registration Number: #{organization.company_registration_number}"
      move_down 1
    end

    move_down 1
    text "Invoice for #{(Date.today - 1.month).strftime('%B %Y')}", style: :bold, color: "999999"

    # Terms
    unless @invoice.terms.blank?
      move_down 20
      text 'Terms'
      text @invoice.terms
    end

    # Notes
    unless @invoice.notes.blank?
      move_down 20
      text 'Notes'
      text @invoice.notes
    end
  end

  def page_numbers
    number_pages "<page>/<total>",{ :at => [bounds.right - 50, 0], :align => :right, :size => 10 }
  end


end