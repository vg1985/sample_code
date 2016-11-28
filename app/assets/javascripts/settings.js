//= require bootstrap.min
//= require modernizr.min
//= require toggles.min
//= require retina.min
//= require jquery.cookies
//= require jquery.gritter.min
//= require select2.min
//= require jquery.tagsinput.min
//= require jquery.gritter.min
//= require custom
//= require did_settings
//= require rate_spinners
//= require inbound_rate_sms
//= require_self

var App = App || {};

$(document).ready(function() {
	App.BWSettingsHandler = (function($) {
		var init = function() {
			$('form.bw_settings_form').on('ajax:beforeSend', function() {
				$("span.bw_settings_form_msg", this).removeClass('text-danger text-success').addClass('text-muted').html('Processing your request ' + ajax_loader);			
			})
			.on('ajax:error', function(e, xhr, status, error) {
				$("span.bw_settings_form_msg", this).removeClass('text-muted text-success').addClass('text-danger').html('Sorry, your request cannot be processed at the moment.');	
			});
		};
		return {
			init: init,
		};
	})(jQuery);

	App.InvoiceSettingsHandler = (function($) {
		var init = function() {
			$('.bc-select2').select2({
				width: '50%'
			});
			$('.pi-select2').select2({
				width: '50%'
			});

			$('form.inv_settings_form').on('ajax:beforeSend', function() {
				$("span.invoice_settings_form_msg", this).removeClass('text-danger text-success').addClass('text-muted').html('Processing your request ' + ajax_loader);
			})
			.on('ajax:error', function(e, xhr, status, error) {
				$("span.invoice_settings_form_msg", this).removeClass('text-muted text-success').addClass('text-danger').html('Sorry, your request cannot be processed at the moment.');	
			});
		};
		return {
			init: init,
		};
	})(jQuery);

	App.ZendeskSettingsHandler = (function($) {
		var init = function(enabled_settings) {
			$("#zendesk_activation_tgl").toggles({ on: enabled_settings[0], checkbox: $("#zendesk_activation_tgl_chkbox"), 'event': 'toggle', text: {on: "Yes", off: "No"}});

			$('form.zendesk_settings_form').on('ajax:beforeSend', function() {
				$("span.zendesk_settings_form_msg", this)
					.removeClass('text-danger text-success')
					.addClass('text-muted')
					.html('Processing your request ' + ajax_loader);			
			})
			.on('ajax:error', function(e, xhr, status, error) {
				$("span.zendesk_settings_form_msg", this).removeClass('text-muted text-success').
				addClass('text-danger').
				html('Sorry, your request cannot be processed at this moment or if you are testing API Credentials, your test failed.');	
			});

			$('#testBtn').click(function() {
				$('#action').val('test');
			});

			$('#updateBtn').click(function() {
				$('#action').val('update');
			});

			$('#export_ne_users').click(function() {
				$("span.zendesk_settings_form_msg", this)
					.removeClass('text-danger text-success')
					.addClass('text-muted')
					.html('Processing your request ' + ajax_loader);
				
				$.get('/settings/export_non_existing');
			});

			$('#export_all_users').click(function() {
				$("span.zendesk_settings_form_msg", this)
					.removeClass('text-danger text-success')
					.addClass('text-muted')
					.html('Processing your request ' + ajax_loader);
				
				$.get('/settings/export_to_zendesk');
			});

			initAssignees();
		};

		var initAssignees = function() {
			$('#setting_zendesk_default_assignee').select2({
				width: '50%'
			});
		}

		return {
			init: init,
			initAssignees: initAssignees
		};
			
	})(jQuery);

	App.SmsSettingsHandler = (function($) {
		var init = function() {
			$('form.sms_settings_form').on('ajax:beforeSend', function() {
				$("span.sms_settings_form_msg", this).removeClass('text-danger text-success').addClass('text-muted').html('Processing your request ' + ajax_loader);
			})
			.on('ajax:error', function(e, xhr, status, error) {
				$("span.sms_settings_form_msg", this).removeClass('text-muted text-success').addClass('text-danger').html('Sorry, your request cannot be processed at this moment or if you are testing API Credentials, your test failed.');
			});

			$('#testBtn').click(function() {
				$('#action').val('test');
			});

			$('#updateBtn').click(function() {
				$('#action').val('update');
			});
		};
		return {
			init: init,
		};
			
	})(jQuery);

	App.OutboundSmsSettingsHandler = (function($) {
		var init = function() {
			$('.var-tooltip').popover({ 
				container: 'body',
				html: true,
				trigger: 'hover click',
				title: 'Email Template Variables',
				content: var_tooltip_html
			});

			$('form.mailer_settings_form').on('ajax:beforeSend', function() {
				$("span.mailer_settings_form_msg", this).removeClass('text-danger text-success').addClass('text-muted').html('Processing your request ' + ajax_loader);			
			})
			.on('ajax:error', function(e, xhr, status, error) {
				$("span.mailer_settings_form_msg", this).removeClass('text-muted text-success').addClass('text-danger').html('Sorry, your request cannot be processed at the moment.');	
			});
		};
		return {
			init: init
		};
			
	})(jQuery);

	App.PaymentGatewaysHandler = (function($) {
		var init = function(enabled_settings) {
			$("#paypal_activation_tgl").toggles({ on: enabled_settings[0], checkbox: $("#paypal_activation_tgl_chkbox"), 'event': 'toggle', text: {on: "Yes", off: "No"}});
			$("#cc_activation_tgl").toggles({ on: enabled_settings[1], checkbox: $("#cc_activation_tgl_chkbox"), 'event': 'toggle', text: {on: "Yes", off: "No"}});
			$("#paypal_deduct_commission_tgl").toggles({ on: enabled_settings[2], checkbox: $("#paypal_deduct_commission_tgl_chkbox"), 'event': 'toggle', text: {on: "Yes", off: "No"}});
			
			//$(".select2").select2({width: '100%'});
			$(".cc_gateway_select2").select2({width: '100%'}).on('change', function() {
				var val = $(this).val();
				$('.first-update-btn').show();
				$('.usa_epay_settings_cont').hide();

				if(val == 'usaepay') {
					$('.first-update-btn').hide();		
					$('.usa_epay_settings_cont').show();
				}
			});

			$('form.paypal_settings_form').on('ajax:beforeSend', function() {
				$("span.paypal_settings_form_msg", this).removeClass('text-danger text-success').addClass('text-muted').html('Processing your request ' + ajax_loader);			
			})
			.on('ajax:error', function(e, xhr, status, error) {
				$("span.bw_settings_form_msg", this).removeClass('text-muted text-success').addClass('text-danger').html('Sorry, your request cannot be processed at the moment.');	
			});

			$('form.cc_settings_form').on('ajax:beforeSend', function() {
				$("span.cc_payment_settings_form_msg", this).removeClass('text-danger text-success').addClass('text-muted').html('Processing your request ' + ajax_loader);			
			})
			.on('ajax:error', function(e, xhr, status, error) {
				$("span.cc_payment_settings_form_msg", this).removeClass('text-muted text-success').addClass('text-danger').html('Sorry, your request cannot be processed at the moment.');	
			});
		};
		return {
			init: init
		};
			
	})(jQuery);

	App.FinanceSettingsHandler = (function($) {
		var init = function() {
			$('#setting_finance_allowed_amounts').tagsInput({
				width:'auto',
				height: '75px',
				defaultText:'',
				minChars : 1,
				maxChars: 10,
				onAddTag: function(tag) {
					if(!(/^\d+$/.test(tag)) || parseInt(tag) < 1) {
						$(this).removeTag(tag);
					}
				}
			});

			$('form.finance_settings_form').on('ajax:beforeSend', function() {
				$("span.finance_settings_form_msg", this).removeClass('text-danger text-success').addClass('text-muted').html('Processing your request ' + ajax_loader);			
			})
			.on('ajax:error', function(e, xhr, status, error) {
				$("span.finance_settings_form_msg", this).removeClass('text-muted text-success').addClass('text-danger').html('Sorry, your request cannot be processed at the moment.');	
			});
		};

		return {
			init: init
		};
	})(jQuery);


	App.MailerSettingsHandler = (function($) {
		var init = function(enabled_settings) {
			$("#mailer_activation_tgl").toggles({ on: enabled_settings[0], checkbox: $("#mailer_activation_tgl_chkbox"), 'event': 'toggle', text: {on: "Yes", off: "No"}});
			
			$('form.mailer_settings_form').on('ajax:beforeSend', function() {
				$("span.mailer_settings_form_msg", this).removeClass('text-danger text-success').addClass('text-muted').html('Processing your request ' + ajax_loader);			
			})
			.on('ajax:error', function(e, xhr, status, error) {
				$("span.mailer_settings_form_msg", this).removeClass('text-muted text-success').addClass('text-danger').html('Sorry, your request cannot be processed at the moment.');	
			});
		};
		return {
			init: init
		};
			
	})(jQuery);

	App.OTPSettingsHandler = (function($) {
		var init = function(enabled_settings) {
			$("#send_sms_tgl").toggles({ on: enabled_settings[0], checkbox: $("#send_sms_tgl_chkbox"), 'event': 'toggle', text: {on: "Yes", off: "No"}});
			$("#sms_email_tgl").toggles({ on: enabled_settings[1], checkbox: $("#send_email_tgl_chkbox"), 'event': 'toggle', text: {on: "Yes", off: "No"}});

			$('form.otp_settings_form').on('ajax:beforeSend', function() {
				$("span.otp_settings_form_msg", this).removeClass('text-danger text-success').addClass('text-muted').html('Processing your request ' + ajax_loader);
			})
			.on('ajax:error', function(e, xhr, status, error) {
				$("span.otp_settings_form_msg", this).removeClass('text-muted text-success').addClass('text-danger').html('Sorry, your request cannot be processed at the moment.');
			});

			$('#setting_otp_postback_method').select2({
				width: '25%',
				minimumResultsForSearch: -1
			});
		};
		return {
			init: init
		};
			
	})(jQuery);

	App.GeneralSettingsHandler = (function($) {
		var init = function() {
			$('form.general_settings_form').on('ajax:beforeSend', function() {
				$("span.general_settings_form_msg", this).removeClass('text-danger text-success').addClass('text-muted').html('Processing your request ' + ajax_loader);
			})
			.on('ajax:error', function(e, xhr, status, error) {
				$("span.general_settings_form_msg", this).removeClass('text-muted text-success').addClass('text-danger').html('Sorry, your request cannot be processed at the moment.');
			});
		};
		return {
			init: init
		};
			
	})(jQuery);

});


