//= require bootstrap.min
//= require modernizr.min
//= require toggles.min
//= require retina.min
//= require jquery.cookies
//= require bootstrap-wizard.min
//= require jquery_nested_form
//= require jquery.validate.min
//= require jquery.datatables.min
//= require select2.min
//= require pwstrength
//= require intl-tel-input
//= require intl-tel-input-utils
//= require custom
//= require rate_spinners
//= require_self

var App = App || {};

/*$(document)
.undelegate('form a.remove_nested_fields', 'click', nestedFormEvents.removeFields)
    .delegate('form a.add_nested_fields',    'click', function() {
		console.log('adding now...');
    })
    .delegate('form a.remove_nested_fields', 'click', function(e) {
		var $link = $(e.currentTarget),
          assoc = $link.data('association'); // Name of child to be removed
      
      var hiddenField = $link.prev('input[type=hidden]');
      hiddenField.val('1');
      
      var field = $link.closest('.fields');
      field.hide();
      
      field
        .trigger({ type: 'nested:fieldRemoved', field: field })
        .trigger({ type: 'nested:fieldRemoved:' + assoc, field: field });
      return false;
    });
	*/
$(document).ready(function() {
	App.intlTelephoneInputHandler = (function($) {
		var initBillingInfoPhones = function() {
			$("#carrier_phone1, #carrier_phone2").intlTelInput({
				numberType: 'FIXED_LINE',
				nationalMode: false,
				separateDialCode: true
			});

			$("#carrier_mobile").intlTelInput({
				nationalMode: false, 
				separateDialCode: true
			})

			$('#carrier_phone1').on('countrychange', function() {
				var countryDate = $(this).intlTelInput("getSelectedCountryData");
				$('#carrier_phone1_code').val('+' + countryDate.dialCode);
			}).trigger('countrychange');

			$('#carrier_phone2').on('countrychange', function() {
				var countryDate = $(this).intlTelInput("getSelectedCountryData");
				$('#carrier_phone2_code').val('+' + countryDate.dialCode);
			}).trigger('countrychange');

			$('#carrier_mobile').on('countrychange', function() {
				var countryDate = $(this).intlTelInput("getSelectedCountryData");
				$('#carrier_mobile_code').val('+' + countryDate.dialCode);
			}).trigger('countrychange');

			$('#carrier_country').change(function() {
				$("#carrier_phone1, #carrier_phone2, #carrier_mobile").intlTelInput("setCountry", $(this).val());
			});
		};

		var initContactPhones = function(parent) {
			var sec_phones, sec_mobiles;

			if (parent == undefined) {
				sec_phones = $('.sec_phones');
				sec_mobiles = $('.sec_mobiles');				
			}
			else {
				sec_phones = parent.find('.sec_phones');
				sec_mobiles = parent.find('.sec_mobiles');
			}

			sec_phones.intlTelInput({
				numberType: 'FIXED_LINE',
				nationalMode: false,
				separateDialCode: true
			});

			sec_mobiles.intlTelInput({nationalMode: false, separateDialCode: true});

			sec_phones.on('countrychange', function() {
				var countryDate = $(this).intlTelInput("getSelectedCountryData");
				$(this).parents('.form-group').find('input[type=hidden]').val('+' + countryDate.dialCode);
				//$('#carrier_phone1_code').val('+' + countryDate.dialCode);
			}).trigger('countrychange');

			sec_mobiles.on('countrychange', function() {
				var countryDate = $(this).intlTelInput("getSelectedCountryData");
				$(this).parents('.form-group').find('input[type=hidden]').val('+' + countryDate.dialCode);
				//$('#carrier_phone1_code').val('+' + countryDate.dialCode);
			}).trigger('countrychange');
		}

		return {
			initBillingInfoPhones: initBillingInfoPhones,
			initContactPhones: initContactPhones
		};
	})(jQuery);

	App.AdminCarrierFormsHandler = (function($) {
		var tfToggleButtons = ['#tf_activation_tgl', '#tf_monthly_tgl', '#tf_pmin_tgl', '#tf_billstart_tgl', '#tf_billinc_tgl'];
		var localToggleButtons = ['#local_activation_tgl', '#local_monthly_tgl', '#local_pmin_tgl', '#local_billstart_tgl', '#local_billinc_tgl'];
		var smsToggleButtons = ['#sms_activation_tgl', '#sms_monthly_tgl', '#sms_outbound_tgl', '#sms_inbound_tgl'];
		var localDidDefaults, tfDidDefaults, localDid, tfDid, smsDidDefaults, smsDid;
		var validationOptions = {};
		var $editFormValidator, $newFormValidator, selTabIndex;
		var secEmailsArray = [], secMobilesArray = [];
		
		var init = function(defaults_rates, carrier_rates, btnStatuses, poBtnStatuses) {
			var charge_failed_val;
			localDidDefaults = defaults_rates[0];
			tfDidDefaults  = defaults_rates[1];
			smsDidDefaults = defaults_rates[2];
			localDid = carrier_rates[0];
			tfDid = carrier_rates[1];
			smsDid = carrier_rates[2];

			$('.toggle_allow_cc').toggles({on: poBtnStatuses[0], checkbox: '#carrier_allow_cc'});
			$('.toggle_allow_paypal').toggles({on: poBtnStatuses[1], checkbox: '#carrier_allow_paypal'}); 
			$('.toggle_allow_paypal_ipn').toggles({on: poBtnStatuses[2], checkbox: '#carrier_allow_paypal_ipn'});

			if(carrier_rates[2][4] === null) {
				charge_failed_val = defaults_rates[2][4];
			}
			else {
				charge_failed_val = carrier_rates[2][4]
			}
			$('#sms_charge_failed_tgl').toggles({on: charge_failed_val, checkbox: '#sms_charge_failed_tgl_chkbox', text: {on: "Yes", off: "No"}});
			
			$(".select2").select2({
    			width: '100%',
  			});

			initNewContacts();

  			$(document).on('nested:fieldAdded:contacts', function(event){
				// this field was just inserted into your form
  			  	// it's a jQuery object already!
  			  	var field = event.field;
  			  	initNewContacts(field);
  			});

			App.intlTelephoneInputHandler.initBillingInfoPhones();

			$.validator.addMethod("alphaOnly", function(value, element) {
				return this.optional(element) || App.alphaNoSpaceRegex.test(value);
			}, "Username can only contain letters and numbers.");

			$.validator.addMethod("i18NumberFormat", function(value, element) {
				return this.optional(element) || /^[\ \-\(\)\d]+$/.test(value);
			}, "Invalid phone number format.");

			$.validator.addMethod("passwordRules", function(value, element) {
				return this.optional(element) || /\d+/.test(value);
			}, "Password must contain atleast one number.");
			
			validationOptions = {
				debug : false,
				ignoreTitle: true,
				highlight : function(element) {
					$(element).closest('.form-group').removeClass('has-success').addClass('has-error');
				},
				success : function(element) {
					$(element).closest('.form-group').removeClass('has-error');
				},
				submitHandler : function(form) {
					// do other things for a valid form
					if(validateSecContacts()) {
						var contactEmails = secEmailsArray.join();
						var contactMobiles = secMobilesArray.join();
						var postData = {emails: contactEmails, mobiles: contactMobiles};

						if($.trim($("#carrier_id").val()) == '') {
							postData.new = 1
						}
						else {
							postData.carrier_id = $("#carrier_id").val();
						}

						if(contactEmails.length > 0 || contactMobiles.length > 0) {
							$.post('/carriers/check_unique_contacts', postData, function(resp) {
								if(resp.found) {
									if(resp.emails.length > 0) {
										var message = "Email(s) " + resp.emails.split(',').toSentence() + " already exist(s) with us. Please enter alternate email(s).";
									}

									if(resp.mobiles.length > 0) {
										var message = "Mobile Number(s) " + resp.mobiles.split(',').toSentence() + " already exist(s) with us. Please enter alternate mobile numbers(s).";
									}

									$('#sec_contact_errmsg').html(message).show();
								}
								else {
									if (App.RateSpinners.validateLocalSpinners() && 
										App.RateSpinners.validateTollfreeSpinners() && 
										App.RateSpinners.validateSmsSpinners()) {
										form.submit();
									}
								}
								
							}, 'json')
						}
						else {
							if (App.RateSpinners.validateLocalSpinners() && 
								App.RateSpinners.validateTollfreeSpinners() && 
								App.RateSpinners.validateSmsSpinners()) {
								form.submit();
							}
						}
					}
				},
				rules : {
					"carrier[account_code]" : {
						required : true,
						digits: true,
						minlength: 5,
						maxlength: 10,
						remote : {
							url : "/carriers/check_account_code",
							type : "get",
							data : {
								carrier_id : function() {
									return $("#carrier_id").val();
								}
							}
						}
					},
					"carrier[user_attributes][username]" : {
						required : true,
						alphaOnly: true,
						minlength: 5,
						maxlength: 30,
						remote : {
							url : "/carriers/check_username",
							type : "get",
							data : {
								user_id : function() {
									return $("#carrier_user_attributes_id").val();
								}
							}
						}
					},
					"carrier[user_attributes][name]" : {
						required : true,
						minlength : 2,
						maxlength : 255
					},
					"carrier[user_attributes][email]" : {
						required : true,
						email : true,
						remote : {
							url : "/carriers/check_email",
							type : "get",
							data : {
								user_id : function() {
									return $("#carrier_user_attributes_id").val();
								}
							},
						}
					},
					"carrier[user_attributes][password]" : {
						minlength : 5,
						maxlength : 15,
						passwordRules: true
					},
					"carrier[user_attributes][password_confirmation]" : {
						equalTo : "#carrier_user_attributes_password"
					},
					"carrier[company_name]" : {
						required : true,
						remote : {
							url : "/carriers/check_company",
							type : "get",
							data : {
								carrier_id : function() {
									return $("#carrier_id").val();
								}
							}
						}
					},
					"carrier[address1]" : {
						required : true,
						minlength : 1,
						maxlength : 50
					},
					"carrier[city]" : {
						required : true,
						minlength : 2,
						maxlength : 25
					},
					"carrier[state]" : {
						required : true
					},
					"carrier[country]" : {
						required : true
					},
					
					"carrier[timezone]" : {
						required : true
					},
					"carrier[phone1]" : {
						required: true,
						minlength: 6,
						i18NumberFormat: true
					},
					"carrier[phone2]" : {
						minlength: 6,
						i18NumberFormat: true
					},
					"carrier[mobile]" : {
						required: true,
						minlength: 6,
						i18NumberFormat: true,
						remote : {
							url : "/carriers/check_mobile",
							type : "get",
							data : {
								carrier_id : function() {
									return $("#carrier_id").val();
								},
								dialcode: function() {
									return $('#carrier_mobile').prev('.flag-container').
											find('.selected-dial-code').html();
								}
							}
						}
					}
				},
				messages : {
					"carrier[account_code]" : {
						remote : "Account code already exists with us."
					},
					"carrier[mobile]" : {
						remote : "Mobile number already exists with us."
					},
					"carrier[company_name]" : {
						remote : "Company name already exists with us."
					},
					"carrier[user_attributes][email]" : {
						remote : "Email already exists with us."
					},
					"carrier[user_attributes][username]" : {
						remote : "Username already exists with us."
					},
					"carrier[user_attributes][password_confirmation]": "This field should match the password."

				}
			};
			
			$editFormValidator = $('#editCarrierForm').validate($.extend(true, {}, validationOptions));
			$newFormValidator = $('#newCarrierForm').validate($.extend(true, {}, validationOptions, {
				rules: {
					"carrier[user_attributes][password]": {required: true},
					"carrier[company_name]": {remote: {
						data: {carrier_id: -1}
					}},
					"carrier[mobile]": {
						remote: {
							data: {user_id: -1},
							complete: function(xhr) {
								$("span#verify_mobile_now_link").hide();
								if(xhr.responseJSON) {
									$("span#verify_mobile_now_link").show();
								}
							}
						}
					},
					"carrier[user_attributes][email]": {remote: {
						data: {user_id: -1}
					}},
					"carrier[user_attributes][username]": {remote: {
						data: {user_id: -1}
					}}
				}
			}));

			$("#carrier_mobile").on("countrychange",
				function(e) {
					$("#carrier_mobile").removeData("previousValue");
					$("#carrier_mobile").valid();
				}
			);

			$('div#editCarrierWizard ul.nav a').click(function() {
				var href = $(this).attr('href');
				selTabIndex = parseInt(href.charAt(href.length -1)) - 1;
				return true;
			});

			//init bootstrap wizard
			$('#editCarrierWizard').bootstrapWizard({
				'nextSelector' : '#inbuilt_next',
				'previousSelector' : '#inbuilt_prev',
				onNext : function(tab, navigation, index) {
					$('#custom_next, #custom_prev').hide();
					$('#inbuilt_next, #inbuilt_prev').show();

					if((index - 1) == 5) {
						return App.RateSpinners.validateLocalSpinners() && App.RateSpinners.validateTollfreeSpinners();
					}
					
					if(index == 2) {
						updatePrimaryUser();
						$('#custom_next, #custom_prev').show();
						$('#inbuilt_next, #inbuilt_prev').hide();
					}
					
					return validateSecContacts() && validateEditForm();
				},
				onPrevious : function(tab, navigation, index) {
					$('#custom_next, #custom_prev').hide();
					$('#inbuilt_next, #inbuilt_prev').show();

					if ((index + 1) == 6) {
						return App.RateSpinners.validateSmsSpinners();
					}

					if((index + 1) == 5) {
						return App.RateSpinners.validateLocalSpinners() && App.RateSpinners.validateTollfreeSpinners();
					}

					if(index == 2) {
						$('#custom_next, #custom_prev').show();
						$('#inbuilt_next, #inbuilt_prev').hide();
					}
					
					return validateSecContacts() && validateEditForm();
				},
				onTabClick: function(tab, navigation, index) {
					if(selTabIndex == 2) {
						$('#custom_next, #custom_prev').show();
						$('#inbuilt_next, #inbuilt_prev').hide();
					}
					else {
						$('#custom_next, #custom_prev').hide();
						$('#inbuilt_next, #inbuilt_prev').show();
					}

					if(index == 6) {
						return App.RateSpinners.validateSmsSpinners();
					}

					if(index == 5) {
						return App.RateSpinners.validateLocalSpinners() && App.RateSpinners.validateTollfreeSpinners();
					}
					
					if(index === 1) {
						updatePrimaryUser();
					}

					if(index == 2) {
						if(validateSecContacts()) {
							var contactEmails = secEmailsArray.join();
							var contactMobiles = secMobilesArray.join();
							var postData = {emails: contactEmails, mobiles: contactMobiles};

							if($.trim($("#carrier_id").val()) == '') {
								postData.new = 1
							}
							else {
								postData.carrier_id = $("#carrier_id").val();
							}

							if(contactEmails.length > 0 || contactMobiles.length > 0) {
								$.post('/carriers/check_unique_contacts', postData, function(resp) {
									if(resp.found) {
										if(resp.emails.length > 0) {
											var message = "Email(s) " + resp.emails.split(',').toSentence() + " already exist(s) with us. Please enter alternate email(s).";
										}

										if(resp.mobiles.length > 0) {
											var message = "Mobile Number(s) " + resp.mobiles.split(',').toSentence() + " already exist(s) with us. Please enter alternate mobile numbers(s).";
										}

										$('#sec_contact_errmsg').html(message).show();
										$('#custom_next, #custom_prev').show();
										$('#inbuilt_next, #inbuilt_prev').hide();
									}
									else {
										$('#editCarrierWizard').bootstrapWizard('show', selTabIndex.toString());
									}
									
								}, 'json');
							}
							else {
								$('#editCarrierWizard').bootstrapWizard('show', selTabIndex.toString());
							}
						}

						return false;
					}
					
					return validateSecContacts() && validateEditForm();
				}
			});
			
			
			$("#cancelForm").click(function() {
				window.location.href = '/carriers';
				return false;
			});

			$('#custom_next').click(function() {
				if(validateSecContacts()) {
					var contactEmails = secEmailsArray.join();
					var contactMobiles = secMobilesArray.join();
					var postData = {emails: contactEmails, mobiles: contactMobiles};

					if($.trim($("#carrier_id").val()) == '') {
						postData.new = 1
					}
					else {
						postData.carrier_id = $("#carrier_id").val();
					}

					if(contactEmails.length > 0 || contactMobiles.length > 0) {
						$.post('/carriers/check_unique_contacts', postData, function(resp) {
							if(resp.found) {
								if(resp.emails.length > 0) {
									var message = "Email(s) " + resp.emails.split(',').toSentence() + " already exist(s) with us. Please enter alternate email(s).";
								}

								if(resp.mobiles.length > 0) {
									var message = "Mobile Number(s) " + resp.mobiles.split(',').toSentence() + " already exist(s) with us. Please enter alternate mobile numbers(s).";
								}
								
								$('#sec_contact_errmsg').html(message).show();
								return false;
							}
							else {
								$(this).hide();
								$('#inbuilt_next').show();
								if(postData.new == 1) {
									$('#newCarrierWizard').bootstrapWizard('next');
								}
								else {
									$('#editCarrierWizard').bootstrapWizard('next');	
								}
							}
							
						}, 'json');
					}
					else {
						$(this).hide();
						$('#inbuilt_next').show();
						if(postData.new == 1) {
							$('#newCarrierWizard').bootstrapWizard('next');
						}
						else {
							$('#editCarrierWizard').bootstrapWizard('next');	
						}
					}
				}
			});

			$('#custom_prev').click(function() {
				if(validateSecContacts()) {
					var contactEmails = secEmailsArray.join();
					var contactMobiles = secMobilesArray.join();
					var postData = {emails: contactEmails, mobiles: contactMobiles};

					postData.carrier_id = $("#carrier_id").val();

					if(contactEmails.length > 0 || contactMobiles.length > 0) {
						$.post('/carriers/check_unique_contacts', postData, function(resp) {
							if(resp.found) {
								if(resp.emails.length > 0) {
									var message = "Email(s) " + resp.emails.split(',').toSentence() + " already exist(s) with us. Please enter alternate email(s).";
								}

								if(resp.mobiles.length > 0) {
									var message = "Mobile Number(s) " + resp.mobiles.split(',').toSentence() + " already exist(s) with us. Please enter alternate mobile numbers(s).";
								}
								
								$('#sec_contact_errmsg').html(message).show();
								return false;
							}
							else {
								$(this).hide();
								$('#inbuilt_prev').show();
								$('#editCarrierWizard').bootstrapWizard('previous');	
							}
							
						}, 'json');
					}
					else {
						$(this).hide();
						$('#inbuilt_prev').show();
						$('#editCarrierWizard').bootstrapWizard('previous');	
					}
				}
			});

			$('#newCarrierWizard').bootstrapWizard({
				'nextSelector' : '#inbuilt_next',
				'previousSelector' : '.previous',
				onNext: function(tab, navigation, index) {
					var total, current, percent;
					
					$('#custom_next').hide();
					$('#inbuilt_next').show();

					$('#newFormFinishBtn').addClass('disabled');
					
					if(validateNewForm() &&
						App.RateSpinners.validateLocalSpinners() &&
						App.RateSpinners.validateTollfreeSpinners() &&
						App.RateSpinners.validateSmsSpinners() &&
						validateSecContacts()) {

						total = navigation.find('li').length;
						current = index + 1;
						percent = (current / total) * 100;
						
						$('#newCarrierWizard').find('.progress-bar').css('width', percent + '%');
						if (index == 6) {
							$('#newFormFinishBtn').removeClass('disabled');
						}
						
						if(index == 2) {
							updatePrimaryUser();
							$('#custom_next').show();
							$('#inbuilt_next').hide();
						}

						return true;
					}
					
					return false;
				},
				onPrevious: function(tab, navigation, index) {
					var total, current, percent;
					
					$('#custom_next').hide();
					$('#inbuilt_next').show();

					$('#newFormFinishBtn').addClass('disabled');
					
					if(validateNewForm() && 
						App.RateSpinners.validateLocalSpinners() && 
						App.RateSpinners.validateTollfreeSpinners() && 
						App.RateSpinners.validateSmsSpinners() && 
						validateSecContacts()) {

						total = navigation.find('li').length;
						current = index + 1;
						percent = (current / total) * 100;
						
						$('#newCarrierWizard').find('.progress-bar').css('width', percent + '%');
						
						if(index == 2) {
							$('#custom_next').show();
							$('#inbuilt_next').hide();
						}

						return true;
					}
					
					return false;
				},
				onTabShow: function(tab, navigation, index) {
					var total, current, percent;
					
					total = navigation.find('li').length;
					current = index + 1;
					percent = (current / total) * 100;
					
					$('#newCarrierWizard').find('.progress-bar').css('width', percent + '%');
				},
				onTabClick: function(tab, navigation, index) {
					return false;
    			}
			});
			
			//init toggle buttons
			$.each(tfToggleButtons, function(i, el) {
				var spinner = '#' + $(el).data('spinner');
				$(el).toggles({ on: btnStatuses[1][i], checkbox: $(el + '_chkbox'), 'event': 'toggle', text: {on: "Yes", off: "No"}});
				bindToggleEvent(el);
				if(btnStatuses[1][i]) {
					App.RateSpinners.disableSpinner(spinner);
					App.RateSpinners.resetTo(spinner, tfDidDefaults[i]);
				}
				else {
					App.RateSpinners.enableSpinner(spinner);
					if(tfDid[i] != null) {
						App.RateSpinners.resetTo(spinner, tfDid[i]);	
					}
					
				}
			});
			
			$.each(localToggleButtons, function(i, el) {
				var spinner = '#' + $(el).data('spinner');
				
				$(el).toggles({ on: btnStatuses[0][i], checkbox: $(el + '_chkbox'), text: {on: "Yes", off: "No"}});
				bindToggleEvent(el);
				
				if(btnStatuses[0][i]) {
					App.RateSpinners.disableSpinner(spinner);
					App.RateSpinners.resetTo(spinner, localDidDefaults[i]);
				}
				else {
					App.RateSpinners.enableSpinner(spinner);
					if(localDid[i] != null) {
						App.RateSpinners.resetTo(spinner, localDid[i]);	
					}
					
				}
			});

			$.each(smsToggleButtons, function(i, el) {
				var spinner = '#' + $(el).data('spinner');
				
				$(el).toggles({ on: btnStatuses[2][i], checkbox: $(el + '_chkbox'), text: {on: "Yes", off: "No"}});
				bindToggleEvent(el);
				
				if(btnStatuses[2][i]) {
					App.RateSpinners.disableSpinner(spinner);
					App.RateSpinners.resetTo(spinner, smsDidDefaults[i]);
				}
				else {
					App.RateSpinners.enableSpinner(spinner);
					if(smsDid[i] != null) {
						App.RateSpinners.resetTo(spinner, smsDid[i]);
					}
					
				}
			});
		};
		
		var validateEditForm = function() {
			var $valid = $('#editCarrierForm').valid();
					
			if (!$valid) {
				$editFormValidator.focusInvalid();
				return false;
			}
			
			return true;
		};
		
		var validateNewForm = function() {
			var $valid = $('#newCarrierForm').valid();
					
			if (!$valid) {
				$newFormValidator.focusInvalid();
				return false;
			}
			
			return true;
		};
		
		var bindToggleEvent = function (el) {
			$(el).on("toggle", function(e) {
				var target = e.currentTarget;
				var spinner = '#' + $(target).data('spinner');
				
				if($(target.nextElementSibling).attr('checked')) {
					App.RateSpinners.disableSpinner(spinner);
					if(spinner.indexOf("local") > 0) {
						var i = localToggleButtons.indexOf('#' + $(target).attr('id'));
						App.RateSpinners.resetTo(spinner, localDidDefaults[i]);		
					}
					else if(spinner.indexOf("sms") > 0) {
						var i = smsToggleButtons.indexOf('#' + $(target).attr('id'));
						App.RateSpinners.resetTo(spinner, smsDidDefaults[i]);
					}
					else {
						var i = tfToggleButtons.indexOf('#' + $(target).attr('id'));
						App.RateSpinners.resetTo(spinner, tfDidDefaults[i]);
					}
				}
				else {
					App.RateSpinners.enableSpinner(spinner);
					if(spinner.indexOf("local") > 0) {
						var i = smsToggleButtons.indexOf('#' + $(target).attr('id'));
						if(smsDid[i] != null) {
							App.RateSpinners.resetTo(spinner, smsDid[i]);	
						}
					}
					else if(spinner.indexOf("sms") > 0) {
						var i = smsToggleButtons.indexOf('#' + $(target).attr('id'));
						App.RateSpinners.resetTo(spinner, smsDidDefaults[i]);
					}
					else {
						var i = tfToggleButtons.indexOf('#' + $(target).attr('id'));
						if(tfDid[i] != null) {
							App.RateSpinners.resetTo(spinner, tfDid[i]);	
						}
					}
				}
																			
			});
		};
		
		var initNewContacts = function(parent) {
			var ctype;
			if(parent == undefined) {
				ctype = '.cont-type';
			}
			else {
				ctype = parent.find('.cont-type');
			};

			$(ctype).select2({
    			width: '130px',
  			});

  			App.intlTelephoneInputHandler.initContactPhones(parent);
		};

		var updatePrimaryUser = function() {
			var dialCode =  $('#carrier_mobile').prev('.flag-container').
							find('.selected-dial-code').html();
			$("#primary_name").val($('#carrier_user_attributes_name').val());
			$("#primary_email").val($('#carrier_user_attributes_email').val());
			$("#primary_phone").val($('#carrier_phone1').val());
			$("#primary_mobile").val(dialCode + " " + $('#carrier_mobile').val());
		};

		var validateSecContacts = function() {
			var email_err = false;
			var phone_err = false;
			var mobile_err = false;
			secEmailsArray = [];
			secMobilesArray = [];

			$('#sec_contact_errmsg').html('').hide();
			
			$('.sec_emails:visible').each(function(i) {
				var $name = $(this).parents('.form-inline').find('.sec_names');
				var value = $(this).val();
				
				$(this).parent('.form-group').removeClass('has-error');
        
        		if (!(/^[a-zA-Z0-9.!#$%&'*+\/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$/.test(value))) {
				  	$(this).parent('.form-group').addClass('has-error');
					email_err = true;
				}
        
        		if($('#primary_email').val() == value) {
					$(this).parent('.form-group').addClass('has-error');
					email_err = true;
				}
        		
        		secEmailsArray.push(value);
			});
			
			if(email_err) {
				$('#sec_contact_errmsg').html('Please enter valid Email in red marked box(es).\
					Email(s) should be unique. Avoid using primary email as any contact email.').show();
				return false;
			}

			var sortedSecEmails = secEmailsArray.sort();
			for (var i = 0; i < sortedSecEmails.length - 1; i++) {
			    if (sortedSecEmails[i + 1] == sortedSecEmails[i]) {
			        $('#sec_contact_errmsg').html('Duplicate contact emails found. Please use unique email for each contact.').
			        show();
			        return false;
			    }
			}
			
			$('.sec_phones:visible').each(function(i) {
				var value = $(this).val();

				$(this).parents('.form-group').removeClass('has-error');
				
				if(!(/^[\ \-\(\)\d]+$/.test(value)) || value.length < 6) {
					$(this).parents('.form-group').addClass('has-error');
					phone_err = true;
				}
			});
			
			if(phone_err) {
				$('#sec_contact_errmsg').html('Please enter valid Phone number in red marked box(es).\
          			Phone number(s) should contain minimum 6 digits.').show();
				return false;
			}
			
			$('.sec_mobiles:visible').each(function(i) {
        		var value = $(this).val();
        		
        		var dialCode =  $(this).prev('.flag-container').
              	find('.selected-dial-code').html();

        		var unformattedVal = dialCode + value.replace(App.unformattedMobileRegex, '');
        
        		$(this).parents('.form-group').removeClass('has-error');

				if (value.length < 6) {
					$(this).parents('.form-group').addClass('has-error');
					mobile_err = true;  
		        }

				if(!mobile_err) {
					if (!(/^[\d\ \(\)-]+$/.test(value))) {
						$(this).parents('.form-group').addClass('has-error');
						mobile_err = true;	
					}

					if($("#primary_mobile").val().replace(App.unformattedMobileRegex, '') == unformattedVal) {
						$(this).parent('.form-group').addClass('has-error');
						mobile_err = true;
					}

					secMobilesArray.push(unformattedVal);
				}
      		});

			if(mobile_err) {
				$('#sec_contact_errmsg').html('Please enter valid Mobile number in red marked box(es).\
			  		Mobile number(s) should be unique and contain minimum 6 digits. Avoid using primary mobile number as any contact mobile number.').show();
				return false;
			}

			var sortedSecMobiles = secMobilesArray.sort();
			for (var i = 0; i < sortedSecMobiles.length - 1; i++) {
				if (sortedSecMobiles[i + 1] == sortedSecMobiles[i]) {
					$('#sec_contact_errmsg').html('Duplicate contact mobile numbers found. Please use unique mobile number for each contact.').show();
			      	return false;
				}
			}

			return true;
		};
  		
		return {
			init: init
		};
	})(jQuery);

	App.RegisterCarrierFormsHandler = (function($) {
		var validationOptions = {};
		var $editFormValidator, $newFormValidator, selTabIndex;
		var emailVerified = mobileVerified = false;
		var secEmailsArray = [], secMobilesArray = [];
		
		var init = function() {
			$('input#carrier_user_attributes_password').pwstrength({
				ui: {
					container: "#pwd-container",
					showVerdictsInsideProgressBar: true,
					viewports: {
			            progress: "#pwstrength_viewport_progress"
			        }
				},
				common: {
					minChar: 5
				}
			});

			$(".select2").select2({
	    		width: '100%'
	  		});

			initNewContacts();

  			$(document).on('nested:fieldAdded:contacts', function(event){
				// this field was just inserted into your form
  			  	// it's a jQuery object already!
  			  	var field = event.field;
  			  	initNewContacts(field);
  			  	dirtyValues[4] = true;
  			});

  			$(document).on('nested:fieldRemoved:contacts', function(event){
				// this field was just inserted into your form
  			  	// it's a jQuery object already!
  			  	var field = event.field;
  			  	dirtyValues[4] = true;
  			});

  			$('span#verify_email_now_link a').click(function() {
  				$('#oauth_element').val('email');
  				$('#oauth_element_val').val($('#carrier_user_attributes_email').val());
  				App.OTPAuth.showDialog('carrier_verify_emobile', function(data) {
  					if(data.verified) {
  						$('span#unverified_email_msg').hide();
  						$('span#verified_email_msg').show();
  						$('span#verify_email_now_link a').hide();
  						$('input#carrier_user_attributes_email').attr('readonly', true);
  						emailVerified = true;
  					}
  					else {
  						$('span#unverified_email_msg').show();
  						$('span#verified_email_msg').hide();
  						$('span#verify_email_now_link a').show();
  						emailVerified = false;
  					}
  				});
  			});

  			$('#carrier_user_attributes_email').on('click blur', function() {
  				if(!$(this).valid()) {
  					$("div#email_verify_links").hide();
  				}
  				else {
  					$("div#email_verify_links").show();	
  				}
  			});

  			$('span#verify_mobile_now_link a').click(function() {
  				$('#oauth_element').val('mobile');
  				$('#oauth_element_val').val($('#carrier_mobile_code').val() + $('#carrier_mobile').val());
  				App.OTPAuth.showDialog('carrier_verify_emobile', function(data) {
  					if(data.verified) {
  						$('span#unverified_mobile_msg').hide();
  						$('span#verified_mobile_msg').show();
  						$('span#verify_mobile_now_link a').hide();
  						$('input#carrier_mobile').attr('readonly', true);
  						mobileVerified = true;
  					}
  					else {
  						$('span#unverified_mobile_msg').show();
  						$('span#verified_mobile_msg').hide();
  						$('span#verify_mobile_now_link a').show();
  						mobileVerified = false;
  					}
  				});
  			});

  			$('#carrier_mobile').on('keyup blur', function() {
  				if(mobileVerified) {
  					$('#verify_mobile_now_link').hide();
  				}
  				else {
  					$('#verify_mobile_now_link').show();
  				}

  				if(!$(this).valid()) {
  					$("div#mobile_verify_links").hide();
  				}
  				else {
  					$("div#mobile_verify_links").show();
  				}
  			});

			App.intlTelephoneInputHandler.initBillingInfoPhones();

			$.validator.addMethod("alphaOnly", function(value, element) {
				return this.optional(element) || App.alphaNoSpaceRegex.test(value);
			}, "Username can only contain letters and numbers.");

			$.validator.addMethod("passwordRules", function(value, element) {
				return this.optional(element) || /\d+/.test(value);
			}, "Password must contain atleast one number.");

			$.validator.addMethod("i18NumberFormat", function(value, element) {
				return this.optional(element) || /^[\ \-\(\)\d]+$/.test(value);
			}, "Invalid phone number format.");

			validationOptions = {
				debug : false,
				ignoreTitle: true,
				highlight: function(element) {
					$(element).closest('.form-group').removeClass('has-success').addClass('has-error');
				},
				success: function(element) {
					$(element).closest('.form-group').removeClass('has-error');
				},
				submitHandler: function(form) {
					// do other things for a valid form
					if(validateSecContacts()) {
						var contactEmails = secEmailsArray.join();
						var contactMobiles = secMobilesArray.join();
						var postData = {emails: contactEmails, mobiles: contactMobiles};

						if($.trim($("#carrier_id").val()) == '') {
							postData.new = 1
						}
						else {
							postData.carrier_id = $("#carrier_id").val();
						}
						
						if(contactEmails.length > 0 || contactMobiles.length > 0) {
							$.post('/carriers/check_unique_contacts', postData, function(resp) {
								if(resp.found) {
									if(resp.emails.length > 0) {
										var message = "Email(s) " + resp.emails.split(',').toSentence() + " already exist(s) with us. Please enter alternate email(s).";
									}

									if(resp.mobiles.length > 0) {
										var message = "Mobile Number(s) " + resp.mobiles.split(',').toSentence() + " already exist(s) with us. Please enter alternate mobile numbers(s).";
									}

									$('#sec_contact_errmsg').html(message).show();
								}
								else {
									if(otpAuthRequired()) {
										App.OTPAuth.showDialog('carrier_update', function() {
											$('#otpid').val(App.OTPAuth.getOTPId());
											$('#otpcode').val(App.OTPAuth.getOTPCode());
											form.submit();
										});
									}
									else {
										form.submit();
									}
								}
								
							}, 'json')
						}
						else {
							if(otpAuthRequired()) {
								App.OTPAuth.showDialog('carrier_update', function() {
									$('#otpid').val(App.OTPAuth.getOTPId());
									$('#otpcode').val(App.OTPAuth.getOTPCode());
									form.submit();
								});
							}
							else {
								form.submit();
							}
						}
					}
				},
				rules : {
					"carrier[account_code]" : {
						required : true,
						digits: true,
						minlength: 5,
						maxlength: 10,
						remote : {
							url : "/carriers/check_account_code",
							type : "get",
							data : {
								carrier_id : function() {
									return $("#carrier_id").val();
								}
							}
						}
					},
					"carrier[user_attributes][username]" : {
						required : true,
						alphaOnly: true,
						minlength: 5,
						maxlength: 30,
						remote : {
							url : "/carriers/check_username",
							type : "get",
							data : {
								user_id : function() {
									return $("#carrier_user_attributes_id").val();
								}
							}
						}
					},
					"carrier[user_attributes][name]" : {
						required : true,
						minlength : 2,
						maxlength : 255
					},
					"carrier[user_attributes][email]" : {
						required : true,
						email : true,
						remote : {
							url : "/carriers/check_email",
							type : "get",
							data : {
								user_id : function() {
									return $("#carrier_user_attributes_id").val();
								}
							},
						}
					},
					"carrier[user_attributes][password]" : {
						minlength : 5,
						maxlength : 15,
						passwordRules: true
					},
					"carrier[user_attributes][password_confirmation]" : {
						equalTo : "#carrier_user_attributes_password"
					},
					"carrier[company_name]" : {
						required : true,
						remote : {
							url : "/carriers/check_company",
							type : "get",
							data : {
								carrier_id : function() {
									return $("#carrier_id").val();
								}
							}
						}
					},
					"carrier[address1]" : {
						required : true,
						minlength : 1,
						maxlength : 50
					},
					"carrier[city]" : {
						required : true,
						minlength : 2,
						maxlength : 25
					},
					"carrier[state]" : {
						required : true
					},
					
					"carrier[country]" : {
						required : true
					},
					
					"carrier[timezone]" : {
						required : true
					},
					"carrier[phone1]" : {
						required: true,
						minlength: 6,
						i18NumberFormat: true
					},
					"carrier[phone2]" : {
						minlength: 6,
						i18NumberFormat: true
					},
					"carrier[mobile]" : {
						required: true,
						minlength: 6,
						i18NumberFormat: true,
						remote : {
							url : "/carriers/check_mobile",
							type : "get",
							data : {
								carrier_id : function() {
									return $("#carrier_id").val();
								},
								dialcode: function() {
									return $('#carrier_mobile').prev('.flag-container').
											find('.selected-dial-code').html();
								}
							}
						}
					}
				},
				messages : {
					"carrier[company_name]" : {
						remote : "Company name already exists with us."
					},
					"carrier[mobile]" : {
						remote : "Mobile number already exists with us."
					},
					"carrier[user_attributes][email]" : {
						remote : "Email already exists with us."
					},
					"carrier[user_attributes][username]" : {
						remote : "Username already exists with us."
					},
					"carrier[user_attributes][password_confirmation]": "This field should match the password."
				}
			};
			
			$editFormValidator = $('#editCarrierForm').validate($.extend(true, {}, validationOptions));
			$newFormValidator = $('#newCarrierForm').validate($.extend(true, {}, validationOptions, {
				rules: {
					"carrier[user_attributes][password]": {required: true},
					"carrier[company_name]": {remote: {
						data: {carrier_id: -1}
					}},
					"carrier[mobile]": {
						remote: {
							data: {user_id: -1},
							complete: function(xhr) {
								$("span#verify_mobile_now_link").hide();
								if(xhr.responseJSON) {
									$("span#verify_mobile_now_link").show();
								}
							}
						}
					},
					"carrier[user_attributes][email]": {
						remote: {
							data: {user_id: -1},
							complete: function(xhr) {
								$("span#verify_email_now_link").hide();
								if(xhr.responseJSON) {
									$("span#verify_email_now_link").show();
								}
							}
						}
					},
					"carrier[user_attributes][username]": {remote: {
						data: {user_id: -1}
					}}
				}
			}));

			$("#carrier_mobile").on("countrychange",
				function(e) {
					$("#carrier_mobile").removeData("previousValue");
					$("#carrier_mobile").valid();
				}
			);

			$('div#editCarrierWizard ul.nav a').click(function() {
				var href = $(this).attr('href');
				selTabIndex = parseInt(href.charAt(href.length -1)) - 1;
				return true;
			});

			$('#custom_prev').click(function() {
				if(validateSecContacts()) {
					var contactEmails = secEmailsArray.join();
					var contactMobiles = secMobilesArray.join();
					var postData = {emails: contactEmails, mobiles: contactMobiles};

					postData.carrier_id = $("#carrier_id").val();

					if(contactEmails.length > 0 || contactMobiles.length > 0) {
						$.post('/carriers/check_unique_contacts', postData, function(resp) {
							if(resp.found) {
								if(resp.emails.length > 0) {
									var message = "Email(s) " + resp.emails.split(',').toSentence() + " already exist(s) with us. Please enter alternate email(s).";
								}

								if(resp.mobiles.length > 0) {
									var message = "Mobile Number(s) " + resp.mobiles.split(',').toSentence() + " already exist(s) with us. Please enter alternate mobile numbers(s).";
								}
								
								$('#sec_contact_errmsg').html(message).show();
								return false;
							}
							else {
								$(this).hide();
								$('#inbuilt_prev').show();
								$('#editCarrierWizard').bootstrapWizard('previous');	
							}
							
						}, 'json');
					}
					else {
						$(this).hide();
						$('#inbuilt_prev').show();
						
						$('#editCarrierWizard').bootstrapWizard('previous');
					}
				}
			});

			//init bootstrap wizard
			$('#editCarrierWizard').bootstrapWizard({
				'nextSelector': '.next',
				'previousSelector': '#inbuilt_prev',
				onNext : function(tab, navigation, index) {
					$('#custom_prev').hide();
					$('#inbuilt_prev').show();

					if(validateEditForm() && validateSecContacts()) {
						if(index == 2) {
							updatePrimaryUser();
							$('#custom_prev').show();
							$('#inbuilt_prev').hide();
						}
						
						return true;
					}
					
					return false;
				},
				onPrevious : function(tab, navigation, index) {
					$('#custom_prev').hide();
					$('#inbuilt_prev').show();
					return validateEditForm() && validateSecContacts();
				},
				onTabClick: function(tab, navigation, index) {
					console.log(index);
					$('#custom_prev').hide();
					$('#inbuilt_prev').show();

					if(index != 2) {
						updatePrimaryUser();
					}

					if(selTabIndex == 2) {
						$('#custom_prev').show();
						$('#inbuilt_prev').hide();
					}

					if(index == 2) {
						if(validateSecContacts()) {
							var contactEmails = secEmailsArray.join();
							var contactMobiles = secMobilesArray.join();
							var postData = {emails: contactEmails, mobiles: contactMobiles};

							if($.trim($("#carrier_id").val()) == '') {
								postData.new = 1;
							}
							else {
								postData.carrier_id = $("#carrier_id").val();
							}

							if(contactEmails.length > 0 || contactMobiles.length > 0) {
								$.post('/carriers/check_unique_contacts', postData, function(resp) {
									if(resp.found) {
										if(resp.emails.length > 0) {
											var message = "Email(s) " + resp.emails.split(',').toSentence() + " already exist(s) with us. Please enter alternate email(s).";
										}

										if(resp.mobiles.length > 0) {
											var message = "Mobile Number(s) " + resp.mobiles.split(',').toSentence() + " already exist(s) with us. Please enter alternate mobile numbers(s).";
										}

										$('#sec_contact_errmsg').html(message).show();
										$('#custom_next, #custom_prev').show();
										$('#inbuilt_next, #inbuilt_prev').hide();
									}
									else {
										$('#editCarrierWizard').bootstrapWizard('show', selTabIndex.toString());
									}
									
								}, 'json');
							}
							else {
								$('#editCarrierWizard').bootstrapWizard('show', selTabIndex.toString());
							}
						}

						return false;
					}
					return validateEditForm() && validateSecContacts();
				}
			});
			
			
			$("#cancelForm").click(function() {
				window.location.href = '/';
				return false;
			});

			$('#tc_chkbox').click(function() {
				if($(this).is(':checked')) {
					$('#newFormFinishBtn').removeClass('disabled');
				}
				else {
					$('#newFormFinishBtn').addClass('disabled');	
				}
			});

			$('#custom_next').click(function() {
				if(validateSecContacts()) {
					var contactEmails = secEmailsArray.join();
					var contactMobiles = secMobilesArray.join();
					var postData = {emails: contactEmails, mobiles: contactMobiles};

					if($.trim($("#carrier_id").val()) == '') {
						postData.new = 1
					}
					else {
						postData.carrier_id = $("#carrier_id").val();
					}

					if(contactEmails.length > 0 || contactMobiles.length > 0) {
						$.post('/carriers/check_unique_contacts', postData, function(resp) {
							if(resp.found) {
								if(resp.emails.length > 0) {
									var message = "Email(s) " + resp.emails.split(',').toSentence() + " already exist(s) with us. Please enter alternate email(s).";
								}

								if(resp.mobiles.length > 0) {
									var message = "Mobile Number(s) " + resp.mobiles.split(',').toSentence() + " already exist(s) with us. Please enter alternate mobile numbers(s).";
								}
								
								$('#sec_contact_errmsg').html(message).show();
								return false;
							}
							else {
								$(this).hide();
								$('#inbuilt_next').show();
								if(postData.new == 1) {
									$('#newCarrierWizard').bootstrapWizard('next');
								}
								else {
									$('#editCarrierWizard').bootstrapWizard('next');	
								}
							}
							
						}, 'json');
					}
					else {
						$(this).hide();
						$('#inbuilt_next').show();
						if(postData.new == 1) {
							$('#newCarrierWizard').bootstrapWizard('next');
						}
						else {
							$('#editCarrierWizard').bootstrapWizard('next');	
						}
					}
				}
			});

			$('#newCarrierWizard').bootstrapWizard({
				'nextSelector' : '#inbuilt_next',
				'previousSelector' : '.previous',
				onNext : function(tab, navigation, index) {
					var total, current, percent;
					
					$('#custom_next').hide();
					$('#inbuilt_next').show();

					$('#newFormFinishBtn').addClass('disabled');
					
					if(validateNewForm() && validateSecContacts()) {
						switch(index) {
							case 1:
								if(!emailVerified) return false;
							break;
							case 2:
								if(!mobileVerified) return false;
								updatePrimaryUser();
								$('#custom_next').show();
								$('#inbuilt_next').hide();
							break;
							case 3:
								if ($('#tc_chkbox').is(':checked')) {
									$('#newFormFinishBtn').removeClass('disabled');	
								}
							break;
						}

						total = navigation.find('li').length;
						current = index + 1;
						percent = (current / total) * 100;
						
						$('#newCarrierWizard').find('.wizard-progress-bar').css('width', percent + '%');
						
						return true;
					}
					
					return false;
				},
				onPrevious : function(tab, navigation, index) {
					var total, current, percent;
					
					$('#custom_next').hide();
					$('#inbuilt_next').show();

					$('#newFormFinishBtn').addClass('disabled');
					
					if(validateNewForm() && validateSecContacts()) {
						total = navigation.find('li').length;
						current = index + 1;
						percent = (current / total) * 100;
						
						$('#newCarrierWizard').find('.wizard-progress-bar').css('width', percent + '%');
						
						if(index == 2) {
							$('#custom_next').show();
							$('#inbuilt_next').hide();
						}

						return true;
					}
					
					return false;
				},
				onTabShow: function(tab, navigation, index) {
					var total, current, percent;
					
					total = navigation.find('li').length;
					current = index + 1;
					percent = (current / total) * 100;
					
					$('#newCarrierWizard').find('.wizard-progress-bar').css('width', percent + '%');
				},
				onTabClick: function(tab, navigation, index) {
					return false;
    			}
			});

			$("#carrier_user_attributes_password").keyup(function () {
				if($(this).val() == '') {
					$('#pwstrength_viewport_progress').hide();
				}
				else {
					$('#pwstrength_viewport_progress').show();
				}

			    if ($("#carrier_user_attributes_password").valid()) {
			    	$('#passwd_valid').removeClass('fa fa-times-circle validity-fail');
			    	$('#passwd_valid').addClass('fa fa-check-circle validity-success');
			    }
			    else {
			    	$('#passwd_valid').removeClass('fa fa-check-circle validity-success');
			    	$('#passwd_valid').addClass('fa fa-times-circle validity-fail');
			    }
			});

			$("#carrier_user_attributes_password_confirmation").keyup(function () {
			    if ($("#carrier_user_attributes_password_confirmation").valid()) {
			    	$('#confirm_passwd_valid').removeClass('fa fa-times-circle validity-fail');
			    	$('#confirm_passwd_valid').addClass('fa fa-check-circle validity-success');
			    }
			    else {
			    	$('#confirm_passwd_valid').removeClass('fa fa-check-circle validity-success');
			    	$('#confirm_passwd_valid').addClass('fa fa-times-circle validity-fail');
			    }
			});
		};	
		
		var validateEditForm = function() {
			var $valid = $('#editCarrierForm').valid();
					
			if (!$valid) {
				$editFormValidator.focusInvalid();
				return false;
			}
			
			return true;
		};
		
		var validateNewForm = function() {
			var $valid = $('#newCarrierForm').valid();
					
			if (!$valid) {
				$newFormValidator.focusInvalid();
				return false;
			}
			
			return true;
		};

		var setDirtyValues = function(values) {
			dirtyValues = values;
		};

		var otpAuthRequired = function() {
			if(dirtyValues[0]) {
  			if($('#carrier_user_attributes_email').val() != dirtyValues[0]) {
  				console.log('Email changed.');
  				return true;
  			}
  
  			var phone1_old = dirtyValues[1].replace(/[^\d]+/g, '');
  			var phone1_new = $("#carrier_phone1").intlTelInput("getNumber").replace(/[^\d]+/g, '');
        
  			var mobile_old = dirtyValues[2].replace(/[^\d]+/g, '');
  			var mobile_new = $("#carrier_mobile").intlTelInput("getNumber").replace(/[^\d]+/g, '');
  			
  			if(phone1_old != phone1_new) {
  				console.log('Phone1 changed');
  				return true
  			}
  
  			if(mobile_old != mobile_new) {
  				console.log('Mobile changed');
  				return true
  			}
  
  			if(dirtyValues[4]) return dirtyValues[4];
  
  			for(var i = 0; i < dirtyValues[3].length; i++) {
  				if($.trim($('#carrier_contacts_attributes_'+ i +'_email').val()) !==  dirtyValues[3][i][2]) {
  					return true;
  				}
  
  				var old_mobile = dirtyValues[3][i][3].replace(/[^0-9]/g, "");
  				var new_mobile = ($('#carrier_contacts_attributes_'+ i +'_mobile_code').val() + 
  									$('#carrier_contacts_attributes_'+ i +'_mobile').val()).replace(/[^0-9]/g, "");
  				
  				if(new_mobile !==  old_mobile) {
  					return true;
  				}
  
  				/*if($.trim($('#carrier_contacts_attributes_'+ i +'_mobile_code').val()) !==  mobile[0]) {
  					return true;
  				}
  
  				if($.trim($('#carrier_contacts_attributes_'+ i +'_mobile').val()) !==  mobile[1]) {
  					return true;
  				}*/
  			}
      }			
			return false;
		};
		
		var initNewContacts = function(parent) {
			var ctype;
			if(parent === undefined) {
				ctype = '.cont-type';
			}
			else {
				ctype = parent.find('.cont-type');
			};

			$(ctype).select2({
    			width: '130px'
  			});

  			App.intlTelephoneInputHandler.initContactPhones(parent);
		};
				
		var updatePrimaryUser = function() {
			var dialCode =  $('#carrier_mobile').prev('.flag-container').
							find('.selected-dial-code').html();
			$("#primary_name").val($('#carrier_user_attributes_name').val());	
			$("#primary_email").val($('#carrier_user_attributes_email').val());
			$("#primary_phone").val($('#carrier_phone1').val());
			$("#primary_mobile").val(dialCode + " " + $('#carrier_mobile').val());
		};

		var validateSecContacts = function() {
			var email_err = false;
			var phone_err = false;
			var mobile_err = false;
			secEmailsArray = [];
			secMobilesArray = [];
			
			$('#sec_contact_errmsg').html('').hide();
			
			$('.sec_emails:visible').each(function(i) {
				var $name = $(this).parents('.form-inline').find('.sec_names');
				var value = $(this).val();
				
				$(this).parent('.form-group').removeClass('has-error');
				
				if (!(/^[a-zA-Z0-9.!#$%&'*+\/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$/.test(value))) {
					$(this).parent('.form-group').addClass('has-error');
					email_err = true;
				}

				if($('#primary_email').val() == value) {
					$(this).parent('.form-group').addClass('has-error');
					email_err = true;
				}
        
        		secEmailsArray.push(value);
			});
			
			if(email_err) {
				$('#sec_contact_errmsg').html('Please enter valid Email in red marked box(es).\
					Email(s) should be unique. Avoid using primary email as any contact email.').show();
				return false;
			}

			var sortedSecEmails = secEmailsArray.sort();
			for (var i = 0; i < sortedSecEmails.length - 1; i++) {
			    if (sortedSecEmails[i + 1] == sortedSecEmails[i]) {
			        $('#sec_contact_errmsg').html('Duplicate contact emails found. Please use unique email for each contact.').
			        show();
			        return false;
			    }
			}
			
			$('.sec_mobiles:visible').each(function(i) {
				var $name = $(this).parents('.form-inline').find('.sec_names');
				var value = $(this).val();
				var dialCode =  $(this).prev('.flag-container').
							find('.selected-dial-code').html();
				var unformattedVal = dialCode + value.replace(App.unformattedMobileRegex, '');
				
				$(this).parents('.form-group').removeClass('has-error');
				
				if (value.length < 6) {
					$(this).parents('.form-group').addClass('has-error');
					mobile_err = true;  
		        }

				if(!mobile_err) {
					if (!(/^[\d\ \(\)-]+$/.test(value))) {
						$(this).parents('.form-group').addClass('has-error');
						mobile_err = true;	
					}

					if($("#primary_mobile").val().replace(App.unformattedMobileRegex, '') == unformattedVal) {
						$(this).parent('.form-group').addClass('has-error');
						mobile_err = true;
					}

					secMobilesArray.push(unformattedVal);
				}
			});

			if(mobile_err) {
				$('#sec_contact_errmsg').html('Please enter valid Mobile number in red marked box(es).\
					Mobile number(s) should be unique. Avoid using primary mobile number as any contact mobile number.').
					show();
				return false;
			}

			var sortedSecMobiles = secMobilesArray.sort();
			for (var i = 0; i < sortedSecMobiles.length - 1; i++) {
			    if (sortedSecMobiles[i + 1] == sortedSecMobiles[i]) {
			        $('#sec_contact_errmsg').html('Duplicate contact mobile numbers found. Please use unique mobile number for each contact.').
			        show();
			        return false;
			    }
			}

			$('.sec_phones:visible').each(function(i) {
				var $name = $(this).parents('.form-inline').find('.sec_names');
				var value = $(this).val();
				
				$(this).parents('.form-group').removeClass('has-error');
				
				if (!(/^[\ \-\(\)\d]+$/.test(value)) || value.length < 6) {
					$(this).parents('.form-group').addClass('has-error');
					phone_err = true;
				}
			});
			
			if(phone_err) {
				$('#sec_contact_errmsg').html('Please enter digits for Phone number in red marked box(es).').show();
				return false;
			}
			
			return true;
		};
  		
		return {
			init: init,
			setDirtyValues: setDirtyValues
		};
	})(jQuery);

	App.AdminCarrierListHandler = (function($) {
		var urls, destroy_carrier, disable_carrier, enable_carrier,
			bulk_operation = false, destroy_link; 

		var init = function(toggleStatuses) {
			$(document).on('click', 'a.close_modal', function() {
				$(this).parents('.modal').modal('hide');					
				bulk_operation = false;
			});

			$("#carrier_select").select2({
  				width: '225px'
  			}).on('change', function() {
				$('#ingress_trunks_table').DataTable().columns(2).search($(this).val()).draw();
  			});

			$("div.checkbox_toggler_container").on('click', '.result_select_all', function() {
				$("div.carriers-container input.carrier-cb:checkbox:not(:checked)").attr('checked', true);	
				toggleGroupButtons();
			});
			
			$("div.checkbox_toggler_container").on('click', '.result_deselect_all', function() {
				$("div.carriers-container input.carrier-cb:checkbox:checked").attr('checked', false);
				toggleGroupButtons();
			});
			
			$("div.checkbox_toggler_container").on('click', '.result_invert_sel', function() {
				$("div.carriers-container input.carrier-cb:checkbox").click();
				toggleGroupButtons();
			});

			$("div.carriers-container").on('click', 'input.carrier-cb:checkbox', function() {
				toggleGroupButtons();
			});

			$('table#carriers_table').on('click', '.carrier_destroy', function() {
				destroy_carrier = $(this).data('carrier-id');
				$('.delete-carrier-confirm-dlg').modal('show');

				return false;
			});

			$('#del_carrier_confirm_ok').click(function () {
				var link = "a#carrier_" + destroy_carrier + "_destroy_link";
				console.log(link);
				$(link).click();
				
				$('.delete-carrier-confirm-dlg').modal('hide');
			});

			$('table#carriers_table').on('click', '.carrier_disable', function() {
				disable_carrier = $(this).data('carrier-id');

				$('.disable-carrier-confirm-dlg').modal('show');

				return false;
			});

			$('#disable_carrier_confirm_ok').click(function () {
				if(bulk_operation) {
					$('form#selected_carriers_form').submit();
				}
				else {
					var link = "a#carrier_" + disable_carrier + "_disable_link";
					$(link).click();	
				}
				
				$('.disable-carrier-confirm-dlg').modal('hide');
				bulk_operation = false;
			});

			$('table#carriers_table').on('click', '.carrier_enable', function() {
				enable_carrier = $(this).data('carrier-id');

				$('.enable-carrier-confirm-dlg').modal('show');

				return false;
			});

			$('#enable_carrier_confirm_ok').click(function () {
				if(bulk_operation) {
					$('form#selected_carriers_form').submit();
				}
				else {
					var link = "a#carrier_" + enable_carrier + "_enable_link";
					$(link).click();
				}

				$('.enable-carrier-confirm-dlg').modal('hide');
				bulk_operation = false;
			});

			$('button.btn_change_all_status').click(function() {
				bulk_operation = true;
				$('form#selected_carriers_form').attr('action', $(this).data('url'));
			});

			$('#carriers_table').DataTable({
				resposive: true,
				/*"sDom": '<"top"l>rt<"bottom"ip><"clear">',*/
				"lengthMenu": [ [5, 10, 25, 50, 100, -1], [5, 10, 25, 50, 100, "All"] ],
				"columnDefs":[
					{
			    	"targets" : 'no-sort',
			    	"orderable" : false,
			    	},
			    	{
				    	"targets": 0,
				    	"createdCell": function (td, cellData, rowData, row, col) {
							$(td).addClass('text-center').html('<input type="checkbox" name="carrier_ids[]" class="carrier-cb" value="'+ cellData +'">');
						}
					},
					/*{
				    	"targets": 3,
				    	"createdCell": function (td, cellData, rowData, row, col) {
				    		$(td).html(cellData);

				    		if(parseInt(cellData) > 0) {
				    			$(td).html('<a href="/ingress_trunks?cid='+ rowData[0] +'">'+ cellData + '</a>');	
				    		}
						}
					},
					{
				    	"targets": 4,
				    	"createdCell": function (td, cellData, rowData, row, col) {
							$(td).html(cellData);
				    		
				    		if(parseInt(cellData) > 0) {
				    			$(td).html('<a href="/egress_trunks?cid='+ rowData[0] +'">'+ cellData + '</a>');	
				    		}
						}
					},*/
					{
				    	"targets": 5,
				    	"createdCell": function (td, cellData, rowData, row, col) {
				    		if(cellData) {
				    			$(td).html('<span class="label label-success">Activated</span>');
				    		}
				    		else {
				    			$(td).html('<span class="label label-warning">Deactivated</span>');
				    		}
						}
					},
					{
						"targets": 6,
						"createdCell": function (td, cellData, rowData, row, col) {
							innerHtml = '';
							
							if(rowData[7] && cellData[0][1]) {
								innerHtml += ' <a href="#" rel="nofollow" data-carrier-id="'+ rowData[0] +'" title="Disable" class="btn btn-warning btn-xs carrier_disable"><span class="glyphicon glyphicon-lock"></a> ';
								innerHtml += ' <a href="/carriers/'+ rowData[0] +'/disable" rel="nofollow" data-remote="true" data-method="put" id="carrier_'+ rowData[0] +'_disable_link"></a>';
							}
							 
							if(!rowData[7] && cellData[0][0]) {
								innerHtml += ' <a href="#" rel="nofollow" data-carrier-id="'+ rowData[0] +'" title="Enable" class="btn btn-primary btn-xs carrier_enable"><span class="glyphicon glyphicon-check"></a> ';
								innerHtml += ' <a href="/carriers/'+ rowData[0] +'/enable" rel="nofollow" data-remote="true" data-method="put" id="carrier_'+ rowData[0] +'_enable_link"></a>';
							}
							
							if(cellData[1]) {
								innerHtml += ' <a class="btn btn-default btn-xs" title="Modify" href="/carriers/'+ rowData[0] +'/edit"><span class="glyphicon glyphicon-edit"></span></a>';
							}

							if(cellData[2]) {
								if(rowData[3] > 0 || rowData[4] > 0) {
									innerHtml += ' <a href="#" rel="nofollow" title="Delete" data-target=".delete-carrier-unempty-dlg" data-toggle="modal" class="btn btn-danger btn-xs"><span class="glyphicon glyphicon-trash"></span></a> ';										
								}
								else {
									innerHtml += ' <a href="#" rel="nofollow" data-carrier-id="'+ rowData[0] +'" title="Delete" class="btn btn-danger btn-xs carrier_destroy"><span class="glyphicon glyphicon-trash"></span></a> ';
									innerHtml += ' <a href="/carriers/'+ rowData[0] +'" rel="nofollow" data-remote="true" data-method="delete" id="carrier_'+ rowData[0] +'_destroy_link"></a>';	
								}
							}
							
							if(cellData[3][0]) {
								innerHtml += ' <a class="btn btn-default btn-xs" title="Masquerade" href="/users/masquerade/' + cellData[3][1] + '"><span class="glyphicon glyphicon-user"></span></a>';
							}
							
				    		$(td).html(innerHtml);
						}
					}
				],
			    "order": [[ 1, "desc" ]],
			    "displayLength": 25,
			    "processing": true,
			    "serverSide": true,
			    "ajax": {
			    	url: urls[0],
			    	method: 'post',
			    	data: {
			    		page: function() {
			    			return $('#carriers_table').DataTable().page.info().page + 1;
			    		}
			    	}	
			    },
			    "language": {
					"paginate": {
						"previous": "<<",
						"next": ">>"
			        },
			        "processing": "Processing... " + window.ajax_loader
			    },
			    "fnDrawCallback": function() { 
			        var paginateRow = $(this).parent().children('div.dataTables_paginate');
			        var pageCount = Math.ceil((this.fnSettings().fnRecordsDisplay()) / this.fnSettings()._iDisplayLength);
			         
			        if (pageCount > 1)  {
			            paginateRow.css("display", "block");
			        } else {
			            paginateRow.css("display", "none");
			        }

			        $(this).find('input.carrier-cb:checkbox').attr('checked', false);
			        toggleGroupButtons();
			    }
			});

			$('div#carriers_table_length select').select2({
				minimumResultsForSearch: -1
			});
		};

		var toggleGroupButtons = function() {
			if ($("div.carriers-container input.carrier-cb:checkbox:checked").length > 0) {
				$('button.btn_change_all_status, #btn_remove_all').removeClass('disabled');	
			}			
			else {
				$('button.btn_change_all_status, #btn_remove_all').addClass('disabled');
			}
		};

		var setUrls = function(arr) {
			urls = arr;
		}

		return {
			init: init,
			setUrls: setUrls
		};	
	})(jQuery);

	App.CarrierChangePassHandler = (function($) {
		var init = function() {
			$.validator.addMethod("passwordRules", function(value, element) {
				return this.optional(element) || /\d+/.test(value);
			}, "Password must contain atleast one number.");

			validationOptions = {
				debug : false,
				ignoreTitle: true,
				highlight : function(element) {
					$(element).closest('.form-group').removeClass('has-success').addClass('has-error');
				},
				success : function(element) {
					$(element).closest('.form-group').removeClass('has-error');
				},
				submitHandler : function(form) {
					form.submit();
				},
				rules : {
					"user[password]" : {
						required: true,
						minlength : 5,
						maxlength : 15,
						passwordRules: true
					},
					"user[password_confirmation]" : {
						equalTo : "#user_password"
					}
				},
				messages : {
					"user[password_confirmation]": "This field should match the password."
				}
			};
			
			$changePassFormValidator = $('#changePassCarrierForm').validate($.extend(true, {}, validationOptions));
		};

		var setUrls = function(arr) {
			urls = arr;
		}

		return {
			init: init,
			setUrls: setUrls
		};	
	})(jQuery);
	
	App.CarrierForgotPassHandler = (function($) {
		var init = function() {
			
			validationOptions = {
				debug : false,
				ignoreTitle: true,
				highlight : function(element) {
					$(element).closest('.form-group').removeClass('has-success').addClass('has-error');
				},
				success : function(element) {
					$(element).closest('.form-group').removeClass('has-error');
				},
				submitHandler : function(form) {
					form.submit();
				},
				rules : {
					"user[email]" : {
						required: true,
						email: true
					}
				}
			};
			$ForgotPassFormValidator = $('#forgotPassCarrierForm').validate($.extend(true, {}, validationOptions));
		};

		var setUrls = function(arr) {
			urls = arr;
		}

		return {
			init: init,
			setUrls: setUrls
		};	
	})(jQuery);
}); 