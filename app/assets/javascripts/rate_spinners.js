var App = App || {};

jQuery(document).ready(function() {
	App.RateSpinners = (function($) {
		var $local_activation_spinner;
		var $local_monthly_spinner;
		var $local_permin_spinner;
		var $local_billstart_spinner;
		var $local_billinc_spinner;
		var $local_spinners;
		
		var $tf_activation_spinner;
		var $tf_monthly_spinner;
		var $tf_permin_spinner;
		var $tf_billstart_spinner;
		var $tf_billinc_spinner;
		var $tf_spinners;

		var $sms_activation_spinner;
		var $sms_monthly_spinner;
		var $sms_oubound_spinner;
		var $sms_inbound_spinner;
		var $sms_spinners;
		
		var DECIMAL_OPTIONS = {
			numberFormat: "n",
			step: 0.0001,
			min: 0.0000,
			max: 99.9999,
			value: 0.0001
		};
		
		var INT_OPTIONS = {
			numberFormat: "n",
			step: 1,
			min: 0,
			max: 60,
			value: 6
		};
		
		var init = function() {
			$local_activation_spinner = $('#local_activation_spinner').spinner(DECIMAL_OPTIONS);
			$local_monthly_spinner = $('#local_monthly_spinner').spinner(DECIMAL_OPTIONS);
			$local_permin_spinner = $('#local_permin_spinner').spinner(DECIMAL_OPTIONS);
			$local_billstart_spinner = $('#local_billstart_spinner').spinner(INT_OPTIONS);
			$local_billinc_spinner = $('#local_billinc_spinner').spinner(INT_OPTIONS);
			
			$local_spinners = [$local_activation_spinner, $local_monthly_spinner, $local_permin_spinner, $local_billstart_spinner, $local_billinc_spinner];
			
			$tf_activation_spinner = $('#tf_activation_spinner').spinner(DECIMAL_OPTIONS);
			$tf_monthly_spinner = $('#tf_monthly_spinner').spinner(DECIMAL_OPTIONS);
			$tf_permin_spinner = $('#tf_permin_spinner').spinner(DECIMAL_OPTIONS);
			$tf_billstart_spinner = $('#tf_billstart_spinner').spinner(INT_OPTIONS);
			$tf_billinc_spinner = $('#tf_billinc_spinner').spinner(INT_OPTIONS);
			
			$tf_spinners = [$tf_activation_spinner, $tf_monthly_spinner, $tf_permin_spinner, $tf_billstart_spinner, $tf_billinc_spinner];

			$sms_activation_spinner = $('#sms_activation_spinner').spinner(DECIMAL_OPTIONS);
			$sms_monthly_spinner = $('#sms_monthly_spinner').spinner(DECIMAL_OPTIONS);
			$sms_oubound_spinner = $('#sms_outbound_spinner').spinner(DECIMAL_OPTIONS);
			$sms_inbound_spinner = $('#sms_inbound_spinner').spinner(DECIMAL_OPTIONS);
			
			$sms_spinners = [$sms_activation_spinner, $sms_monthly_spinner, $sms_oubound_spinner, $sms_inbound_spinner];
		};
		
		var reset = function(type, values) {
			if("local" == type) {
				$local_activation_spinner.spinner("value", values[0]);
				$local_monthly_spinner.spinner("value", values[1]);
				$local_permin_spinner.spinner("value", values[2]);
				$local_billstart_spinner.spinner("value", values[3]);
				$local_billinc_spinner.spinner("value", values[4]);
			}
			if("tf" == type) {
				$tf_activation_spinner.spinner("value", values[0]);
				$tf_monthly_spinner.spinner("value", values[1]);
				$tf_permin_spinner.spinner("value", values[2]);
				$tf_billstart_spinner.spinner("value", values[3]);
				$tf_billinc_spinner.spinner("value", values[4]);
			}
			if("sms" == type) {
				$sms_activation_spinner.spinner("value", values[0]);
				$sms_monthly_spinner.spinner("value", values[1]);
				$sms_oubound_spinner.spinner("value", values[2]);
				$sms_inbound_spinner.spinner("value", values[3]);
			}
		};
		
		var resetTo = function(selector, val) {
			$(selector).spinner('value', val);
		};
		
		var validateLocalSpinners = function() {
			var isValid = true;
			$.each($local_spinners, function(i, $el) {
				var errorMsg = '';
				var value = $el.spinner("value");
				var min = $el.spinner("option", "min");
				var max = $el.spinner("option", "max");
				var id = $el.attr('id');
				
				if(value == null){
					errorMsg = 'Please input a number.';
					isValid = false;
				}
				else if((i == 3 || i == 4) && /\D/.test(value)){
					errorMsg = 'Please input a integer value.';
					isValid = false;
				}
				else {
					if(value < min || value > max) {
						errorMsg = 'Please select the value that lie between ' +  min + ' to ' + max + '.';
						isValid = false;
					}
				}
				
				if(errorMsg != '') {
					$('#'+id+'_error').html(errorMsg);
					$('.'+id+'_group').removeClass('has-success').addClass('has-error');
				}
				else {
					$('#'+id+'_error').html('');
					$('.'+id+'_group').removeClass('has-error');
				}
			});
			
			return isValid;
		};
		
		var validateTollfreeSpinners = function() {
			var isValid = true;
			$.each($tf_spinners, function(i, $el) {
				var errorMsg = '';
				var value = $el.spinner("value");
				var min = $el.spinner("option", "min");
				var max = $el.spinner("option", "max");
				var id = $el.attr('id');
				
				if(value == null){
					errorMsg = 'Please input a number.';
					isValid = false;	
				}
				else if((i == 3 || i == 4) && /\D/.test(value)){
					errorMsg = 'Please input a integer value.';
					isValid = false;	
				}
				else {
					if(value < min || value > max) {
						errorMsg = 'Please select the value that lie between ' +  min + ' to ' + max + '.';
						isValid = false;
					}	
				}
				
				if(errorMsg != '') {
					$('#'+id+'_error').html(errorMsg);
					$('.'+id+'_group').removeClass('has-success').addClass('has-error');	
				}
				else {
					$('#'+id+'_error').html('');
					$('.'+id+'_group').removeClass('has-error');								
				}
			});
			
			return isValid;
		};

		var validateSmsSpinners = function() {
			var isValid = true;
			$.each($sms_spinners, function(i, $el) {
				var errorMsg = '';
				var value = $el.spinner("value");
				var min = $el.spinner("option", "min");
				var max = $el.spinner("option", "max");
				var id = $el.attr('id');
				
				if(value == null){
					errorMsg = 'Please input a number.';
					isValid = false;	
				}
				else if((i > 100) && /\D/.test(value)){
					errorMsg = 'Please input a integer value.';
					isValid = false;	
				}
				else {
					if(value < min || value > max) {
						errorMsg = 'Please select the value that lie between ' +  min + ' to ' + max + '.';
						isValid = false;
					}	
				}
				
				if(errorMsg != '') {
					$('#'+id+'_error').html(errorMsg);
					$('.'+id+'_group').removeClass('has-success').addClass('has-error');	
				}
				else {
					$('#'+id+'_error').html('');
					$('.'+id+'_group').removeClass('has-error');								
				}
			});
			
			return isValid;
		};
		
		
		var removeErrMsgsForLocal = function() {
			$.each($local_spinners, function(i, $el) {
				var id = $el.attr('id');
				$('#'+id+'_error').html('');
			});
		};
		
		var removeErrMsgsForTollfree = function() {
			$.each($tf_spinners, function(i, $el) {
				var id = $el.attr('id');
				$('#'+id+'_error').html('');
			});
		};

		var removeErrMsgsForSms = function() {
			$.each($sms_spinners, function(i, $el) {
				var id = $el.attr('id');
				$('#'+id+'_error').html('');
			});
		};
		
		var disableLocalSpinners = function() {
			$.each($local_spinners, function(i, $el) {
				$el.spinner("disable");
			});
		};
		
		var disableTollfreeSpinners = function() {
			$.each($tf_spinners, function(i, $el) {
				$el.spinner("disable");
			});
		};

		var disableSmsSpinners = function() {
			$.each($sms_spinners, function(i, $el) {
				$el.spinner("disable");
			});
		};
		
		var enableLocalSpinners = function() {
			$.each($local_spinners, function(i, $el) {
				$el.spinner("enable");
			});
		};
		
		var enableTollfreeSpinners = function() {
			$.each($tf_spinners, function(i, $el) {
				$el.spinner("enable");
			});
		};

		var enableSmsSpinners = function() {
			$.each($sms_spinners, function(i, $el) {
				$el.spinner("enable");
			});
		};
		
		var disableSpinner = function(selector) {
			$(selector).spinner("disable");
		};
		
		var enableSpinner = function(selector) {
			$(selector).spinner("enable");
		};
		
		return {
			init: init,
			reset: reset,
			resetTo: resetTo,
			validateLocalSpinners: validateLocalSpinners,
			validateTollfreeSpinners: validateTollfreeSpinners,
			validateSmsSpinners: validateSmsSpinners,
			disableLocalSpinners: disableLocalSpinners,
			enableLocalSpinners: enableLocalSpinners,
			disableTollfreeSpinners: disableTollfreeSpinners,
			enableTollfreeSpinners: enableTollfreeSpinners,
			disableSmsSpinners: disableSmsSpinners,
			enableSmsSpinners: enableSmsSpinners,
			disableSpinner: disableSpinner,
			enableSpinner: enableSpinner,
			removeErrMsgsForLocal: removeErrMsgsForLocal, 
			removeErrMsgsForTollfree: removeErrMsgsForTollfree,
			removeErrMsgsForSms: removeErrMsgsForSms
		};
			
	})(jQuery);
});