//= require bootstrap.min
//= require modernizr.min
//= require toggles.min
//= require retina.min
//= require jquery.cookies
//= require jquery.gritter.min
//= require select2.min
//= require jquery.tagsinput.min
//= require jquery.validate.min
//= require custom
//= require_self

var App = App || {};

$(document).ready(function() {
	App.CreditCardsHandler = (function($) {
		var init = function(enabled_settings) {
			$("#auto_recharge_activation_tgl").toggles({ on: enabled_settings[0], checkbox: $("#auto_recharge_activation_tgl_chkbox"), 'event': 'toggle', text: {on: "Yes", off: "No"}});
			$("#lc_notification_activation_tgl").toggles({ on: enabled_settings[1], checkbox: $("#lc_notification_activation_tgl_chkbox"), 'event': 'toggle', text: {on: "Yes", off: "No"}});
			
			//$(".select2").select2({width: '100%'});
			$(".select2").select2({width: '75%'});


			autorechargeValidationOptions = {
				debug : false,
				highlight : function(element) {
					$(element).closest('.form-group').removeClass('has-success').addClass('has-error');
				},
				success : function(element) {
					$(element).closest('.form-group').removeClass('has-error');
				},
				submitHandler : function(form) {
					// do other things for a valid form
					$.rails.handleRemote($(form));
				},
				errorPlacement: function(error, element) {
					if (element.attr("id") == "carrier_setting_auto_recharge_balance_threshold") {
						$("#balance_threshold_error").html(error);
				    } 
				    else if(element.attr("id") == "carrier_setting_auto_recharge_recharge_amount") {
				    	$("#recharge_amount_error").html(error);	
				    }
				    else {
				        // the default error placement for the rest
				        error.insertAfter(element);
				    }
				},
				rules : {
					"carrier_setting[auto_recharge_storage_id]" : {
						required : function() {
							//return $('#auto_recharge_activation_tgl_chkbox').is(':checked');
							return false;
						}
					},
					"carrier_setting[auto_recharge_balance_threshold]": {
						required : function() {
							return $('#auto_recharge_activation_tgl_chkbox').is(':checked');
						},
						digits: true
					},
					"carrier_setting[auto_recharge_recharge_amount]": {
						required : function() {
							return $('#auto_recharge_activation_tgl_chkbox').is(':checked');
						},
						digits: true
					}
				}
			}; 

			lowcreditValidationOptions = {
				debug : false,
				highlight : function(element) {
					$(element).closest('.form-group').removeClass('has-success').addClass('has-error');
				},
				success : function(element) {
					$(element).closest('.form-group').removeClass('has-error');
				},
				submitHandler : function(form) {
					// do other things for a valid form
					$.rails.handleRemote($(form));
				},
				errorPlacement: function(error, element) {
					if (element.attr("id") == "carrier_setting_lc_notification_balance_threshold") {
						$("#lc_balance_threshold_error").html(error);
				    } 
				    else {
				        // the default error placement for the rest
				        error.insertAfter(element);
				    }
				},
				rules : {
					"carrier_setting[lc_notification_balance_threshold]": {
						required : function() {
							return $('#lc_notification_activation_tgl_chkbox').is(':checked');
						},
						digits: true
					}
				}
			}; 

			$auto_recharge_settings_form = $('.auto_recharge_settings_form').validate(autorechargeValidationOptions);
			$low_credit_notifications_settings_form = $('.low_credit_notification_settings_form').validate(lowcreditValidationOptions);

			$('form.auto_recharge_settings_form').on('ajax:beforeSend', function() {
				$("span.automatic_recharge_settings_form_msg", this).removeClass('text-danger text-success').addClass('text-muted').html('Processing your request ' + ajax_loader);			
			})
			.on('ajax:error', function(e, xhr, status, error) {
				$("span.automatic_recharge_settings_form_msg", this).removeClass('text-muted text-success').addClass('text-danger').html('Sorry, your request cannot be processed at the moment.');	
			});

			$('form.low_credit_notification_settings_form').on('ajax:beforeSend', function() {
				$("span.low_credit_notification_settings_form_msg", this).removeClass('text-danger text-success').addClass('text-muted').html('Processing your request ' + ajax_loader);			
			})
			.on('ajax:error', function(e, xhr, status, error) {
				$("span.low_credit_notification_settings_form_msg", this).removeClass('text-muted text-success').addClass('text-danger').html('Sorry, your request cannot be processed at the moment.');	
			});
		};
		return {
			init: init
		};
			
	})(jQuery);

});


