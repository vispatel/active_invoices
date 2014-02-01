#coding: utf-8
include ActionView::Helpers::NumberHelper

def generate_invoice(invoice)
  # Generate invoice
  Prawn::Document.generate @invoice.invoice_location do |pdf|
    organization = invoice.client.organization
    # Title
    # text "Invoice ##{invoice.code}", :size => 25
    pdf.font_size 10
    pdf.bounding_box([350, 690], :width => 200, :height => 100) do
      pdf.text organization.name, :style => :bold
      pdf.move_down 1
      [
        organization.street_1,
        organization.street_2,
        organization.city,
        organization.zip_code,
        "VAT: #{organization.vat_number}"
      ].each do |line|
        pdf.text line
        pdf.move_down 1
      end
    end

    # Client info
    pdf.bounding_box([0, 600], :width => 250, :height => 100) do
      pdf.horizontal_rule
      pdf.move_down 10
      pdf.text invoice.client.name
      invoice.client.address.split(',').each do |line|
        pdf.text line
      end
      pdf.text invoice.client.phone
    end

    # Invoice number and due date
    pdf.bounding_box([350, 600], :width => 200, :height => 100) do
      pdf.horizontal_rule
      pdf.move_down 10
      pdf.text "INVOICE #{invoice.code.to_s.rjust(3, '0')}", :size => 14, :style => :bold
      pdf.move_down 1
      pdf.text l(invoice.created_at, :format => :pdf), :size => 12, :style => :bold
      pdf.move_down 1
      due = invoice.due_date.blank? ? "on receipt" : l(invoice.due_date, :format => :pdf)
      pdf.text "Payment Due by #{due}", :size => 10, :style => :bold, :color => "999999"
    end

    # Client info
    pdf.move_down 20

    # Items
    invoice_services_data = []
    invoice_services_data << ["Quantity", "Details", "Unit Price", "VAT", "Net Subtotal"]

    items = invoice.items.collect do |item|
      invoice_services_data << [item.quantity.to_s, item.description, number_to_currency(item.amount), number_to_percentage(item.tax, :strip_insignificant_zeros => true), number_to_currency(item.total)]
    end

    invoice_services_data << [" ", " ", " ", " ", " "]

    pdf.table(invoice_services_data, :width => pdf.bounds.width) do
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

    pdf.move_down 1

    # Item totals
    invoice_services_totals_data = [
      ["Net Total", number_to_currency(invoice.subtotal)],
      ["VAT", number_to_currency(invoice.taxes)],
      ["GBP Total", number_to_currency(invoice.total)]
    ]

    pdf.table(invoice_services_totals_data, :position => :right, :width => pdf.bounds.width) do
      style(row(0..2).columns(1), :width => 75 )
      style(column(0..1), :align => :right, :border_color => 'dddddd', :borders => [:top])
      style(row(2), :font_style => :bold)
    end

    # Bank details
    pdf.bounding_box([0, 300], :width => 200, :height => 100) do
      pdf.text "Payment details", :style => :bold
      pdf.move_down 10
      [organization.bank_name,
      "Bank/Sort Code: #{organization.sort_code}",
      "Account Number: #{organization.account_number}",
      "Payment Reference: #{invoice.code}"].each do |line|
        pdf.text line
        pdf.move_down 1
      end
    end


    # Terms
    unless invoice.terms.blank?
      pdf.move_down 20
      pdf.text 'Terms'
      pdf.text invoice.terms
    end

    # Notes
    unless invoice.notes.blank?
      pdf.move_down 20
      pdf.text 'Notes'
      pdf.text invoice.notes
    end

  end
end


ActiveAdmin.register Invoice do
  scope :all, :default => true
  scope :draft do |invoices|
    invoices.where(:status => Invoice::STATUS_DRAFT)
  end

  scope :sent do |invoices|
    invoices.where(:status => Invoice::STATUS_SENT)
  end

  scope :paid do |invoices|
    invoices.where(:status => Invoice::STATUS_PAID)
  end

  index do
    column :status do |invoice|
      status_tag invoice.status, invoice.status_tag
    end
    column :code do |invoice|
      link_to "##{invoice.code}", admin_invoice_path(invoice)
    end

    column :client

    column "Issued" do |invoice|
      due = if invoice.due_date
        " (due in #{distance_of_time_in_words Time.now, invoice.due_date})"
      else
        ""
      end

      "#{l invoice.created_at, :format => :short}" + due
    end
    column :total do |invoice|
      number_to_currency invoice.total
    end

    column do |invoice|
      link_to("Details", admin_invoice_path(invoice)) + " | " + \
      link_to("Edit", edit_admin_invoice_path(invoice)) + " | " + \
      link_to("Delete", admin_invoice_path(invoice), :method => :delete, :confirm => "Are you sure?")
    end
  end

  # -----------------------------------------------------------------------------------
  # PDF

  action_item :only => :show do
    link_to "Generate PDF", generate_pdf_admin_invoice_path(resource)
  end

  action_item :only => :index do
    link_to "Import Invoice from Intervals", import_invoice_admin_invoices_path
  end

  member_action :generate_pdf do
    @invoice = Invoice.find(params[:id])
    generate_invoice(@invoice)

    # Send file to user
    send_file @invoice.invoice_location, :type => "application/pdf"
  end

  collection_action :import_invoice, :method => :get do
    intervals = Intervals.new(current_admin_user)

    @invoice = Invoice.new(code: Invoice.suggest_code)
    # TODO Store rate and service provided (description) in db against a client
    item = Item.new(quantity: intervals.days_to_bill, description: 'Web development', amount: 100)
    @invoice.items << item

    #TODO For now we're picking the first client, in the future the import_invoice option should be done
    # given account.
    @invoice.client = current_admin_user.clients.first

    @invoice.admin_user = current_admin_user
    @invoice.save!
    generate_invoice(@invoice)
    # Send file to user
    send_file @invoice.invoice_location, :type => "application/pdf"
  end

  # -----------------------------------------------------------------------------------

  # -----------------------------------------------------------------------------------
  # Email sending

  action_item :only => :show do
    link_to "Send", send_invoice_admin_invoice_path(resource)
  end

  member_action :send_invoice do
    @invoice = Invoice.find(params[:id])
  end

  member_action :dispatch_invoice, :method => :post do
    @invoice = Invoice.find(params[:id])

    # Generate the PDF invoice if neccesary
    generate_invoice(@invoice) if params[:attach_pdf]

    # Attach our own email if we want to send a copy to ourselves.
    params[:recipients] += ", #{current_admin_user.email}" if params[:send_copy]

    # Send all emails
    params[:recipients].split(',').each do |recipient|
      InvoicesMailer.send_invoice(@invoice.id, recipient.strip, params[:subject], params[:message], !!params[:attach_pdf]).deliver
    end

    # Change invoice status to sent
    @invoice.status = Invoice::STATUS_SENT
    @invoice.save

    redirect_to admin_invoice_path(@invoice), :notice => "Invoice sent successfully"
  end

  # -----------------------------------------------------------------------------------

  show :title => :code do
    panel "Invoice Details" do
      attributes_table_for invoice do
        row("Code") { invoice.code }
        row("Status") { status_tag invoice.status, invoice.status_tag }
        row("Issue Date") { invoice.created_at }
        row("Due Date") { invoice.due_date }
      end
    end

    panel "Items" do
      table_for invoice.items do |t|
        t.column("Qty.") { |item| number_with_delimiter item.quantity }
        t.column("Description") { |item| item.description }
        t.column("VAT") { |item| number_to_percentage(item.tax, :strip_insignificant_zeros => true) }
        t.column("Per Unit") { |item| number_to_currency item.amount }
        t.column("Total") { |item| number_to_currency item.total}

        # Show the tax, discount, subtotal and total
        tr do
          3.times { td "" }
          td "Discount:", :style => "text-align:right; font-weight: bold;"
          td "#{number_with_delimiter(invoice.discount)}%"
        end if invoice.discount > 0

        tr do
          3.times { td "" }
          td "Net Total:", :style => "text-align:right; font-weight: bold;"
          td "#{number_to_currency(invoice.subtotal)}"
        end

        tr do
          3.times { td "" }
          td "VAT :", :style => "text-align:right; font-weight: bold;"
          td "#{number_to_currency(invoice.taxes)}"
        end

        tr do
          3.times { td "" }
          td "Total:", :style => "text-align:right; font-weight: bold;"
          td "#{number_to_currency(invoice.total)}", :style => "font-weight: bold;"
        end
      end
    end

    panel "Other" do
      attributes_table_for invoice do
        row("Terms") { simple_format invoice.terms }
        row("Notes") { simple_format invoice.notes }
      end
    end
  end

  filter :client
  filter :code
  filter :due_date

  sidebar "Bill To", :only => :show do
    attributes_table_for invoice.client do
      row("Name") { link_to invoice.client.name, admin_client_path(invoice.client) }
      row("Email") { mail_to invoice.client.email }
      row("Address") { invoice.client.address }
      row("Phone") { invoice.client.phone }
    end
  end

  sidebar "Total", :only => :show do
    h1 number_to_currency(invoice.total), :style => "text-align: center; margin-top: 20px"
  end

  form do |f|
    f.inputs "Client" do
      f.input :client, :collection => current_admin_user.clients, :include_blank => false
    end

    f.inputs "Items" do
      f.has_many :items do |i|
        i.input :_destroy, :as => :boolean, :label => "Delete this item" unless i.object.id.nil?
        i.input :quantity
        i.input :description
        i.input :tax, :input_html => { :style => "width: 35px"}, :hint => "This should be a percentage, from 0 to 100 (without the % sign)"
        i.input :amount
      end
    end

    f.inputs "Options" do
      f.input :code, :hint => "The invoice's code, should be incremental."
      f.input :status, :collection => Invoice.status_collection, :include_blank => false
      f.input :due_date, :as => :datepicker
      f.input :discount, :input_html => {:style => "width: 35px"}, :hint => "This should be a percentage, from 0 to 100 (without the % sign)"
    end

    f.inputs "Other Fields" do
      f.input :terms, :input_html => { :rows => 4 }, :label => "Terms & Conditions"
      f.input :notes, :input_html => { :rows => 4 }
    end

    f.buttons
  end

end
