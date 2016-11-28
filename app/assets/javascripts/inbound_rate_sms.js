var App = App || {};

jQuery(document).ready(function() {
	App.InboundRateSmsFormHandler = (function($) {
		var init = function(charge_failed) {
			$("#submit_sms_form").on('click', function() {
				App.RateSpinners.removeErrMsgsForSms();
				
				if(App.RateSpinners.validateSmsSpinners()) {
					disableActions();
					$(this).parents('form').submit();
				}
				
				return false;	
			});
			
			$('#sms_charge_failed_tgl').toggles({on: charge_failed, checkbox: '#sms_charge_failed_tgl_chkbox', text: {on: "Yes", off: "No"}});

			$('form#edit_did_sms_form').on('ajax:beforeSend', function() {
				App.RateSpinners.disableSmsSpinners();
				$("span#edit_did_sms_form_msg").removeClass('text-danger text-success').addClass('text-muted').html('Processing your request ' + ajax_loader);			
			})
			.on('ajax:error', function(e, xhr, status, error) {
				App.RateSpinners.enableSmsSpinners();
				enableActions();
				$("span#edit_did_sms_form_msg").removeClass('text-muted text-success').addClass('text-danger').html('Sorry, your request cannot be processed at the moment.');	
			}).
			on('ajax:complete', function() {
				$("span#edit_did_sms_form_msg").html('');
			});
			
			$("#reset_sms_form").click(function() {
				App.RateSpinners.reset('sms', [0,0,0,0]);
				App.RateSpinners.removeErrMsgsForSms();
				return false;
			});
		};
		
		var enableActions = function() {
			$('#reset_sms_form, #submit_sms_form').attr('disabled', false);
		};
		
		var disableActions = function() {
			$('#reset_sms_form, #submit_sms_form').attr('disabled', true);
		};
		
		return {
			init: init,
			enableActions: enableActions,
			disableActions: disableActions
		};
			
	})(jQuery);
});