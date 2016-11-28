//= require bootstrap.min
//= require modernizr.min
//= require toggles.min
//= require retina.min
//= require jquery.cookies
//= require jquery.validate.min
//= require select2.min
//= require jquery.gritter.min
//= require custom
//= require_self

var App = App || {};

jQuery(document).ready(function() {
	App.RoleFormHandler = (function($) {
		var urls;

		var init = function(permObj) {
			$("#carriers_select").select2({
    			width: '100%',
  			});

			var validationOptions = {
				debug : false,
				ignoreTitle: true,
				highlight: function(element) {
					$(element).closest('.form-group').removeClass('has-success').addClass('has-error');
				},
				success: function(element) {
					$(element).closest('.form-group').removeClass('has-error');
				},
				submitHandler: function(form) {
					if(validCarriers()) {
						$('.submit-btn').attr("disabled", true);
						$.rails.handleRemote($(form));	
					}
				},
				rules: {
					"role[name]" : {
						required : true,
						minlength: 3,
						maxlength: 25,
						remote : {
							url : urls[0],
							type : "get",
						}
					}
				},
				messages: {
					"role[name]" : {
						remote : "This role already exists with us."
					}
				}
			}

			$editFormValidator = $('#editRoleForm').validate($.extend(true, {}, validationOptions, {
				rules: {
					"role[name]": {remote: {
						data: {id: $('#role_id').val()}
					}}
				}
			}));
			
			$newFormValidator = $('#newRoleForm').validate($.extend(true, {}, validationOptions, {}));
			
			$('.module-enabler').change(function() {
				var module = $(this).data('module');
				if($(this).is(':checked')){
					$('.module-' + module).attr('disabled', false);
				}
				else {
					$('.module-' + module).attr('disabled', true);
				}
			}).trigger('change');

			$('#all_carriers_cb').click(function() {
				toggleCarriersSelection(this);
			});

			toggleCarriersSelection($('#all_carriers_cb'));
			
		};

		var toggleCarriersSelection = function(el) {
			if($(el).is(':checked')) {
				$('#carriers_select').select2('val', '').attr('disabled', true);
			}
			else {
				$('#carriers_select').attr('disabled', false);
			}
		};

		var validCarriers = function() {
			if($('#all_carriers_cb').attr('disabled')) return true;

			$('#no_carrier_msg').hide();
			
			if(!$('#all_carriers_cb').is(':checked')) {
				if(!$('#carriers_select').val()) {
					$('#no_carrier_msg').show();
					return false;
				}
			}

			return true;
		}

		var setUrls = function(arr) {
			urls = arr;
		};

		return {
			init: init,
			setUrls: setUrls
		}
	})(jQuery);
});
