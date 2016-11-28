//= require bootstrap.min
//= require modernizr.min
//= require toggles.min
//= require retina.min
//= require jquery.cookies
//= require jquery.validate.min
//= require select2.min
//= require jquery.datatables.min
//= require bootstrap-editable.min
//= require jquery.gritter.min
//= require custom
//= require did_settings
//= require rate_spinners
//= require inbound_rate_sms
//= require_self

var App = App || {};

jQuery(document).ready(function() {
	var urls;

	jQuery.validator.addMethod("areacodeStartRest", function(value, element) {
  		return this.optional(element) || !(value.startsWith("0") || value.startsWith("1") || value.startsWith("37") || value.startsWith("96"));
	}, "This is an invalid Areacode.");
	
	jQuery.validator.addMethod("areacodeEndRest", function(value, element) {
  		return this.optional(element) || !value.endsWith("11");
	}, "This is an invalid Areacode.");
	
	jQuery.validator.addMethod("areacodeMidRest", function(value, element) {
  		return this.optional(element) || !(value[1] === '9');
	}, "This is an invalid Areacode.");
	
	jQuery.validator.addMethod("areacodeTFNpaRest", function(value, element) {
		console.log(jQuery.inArray(value, ["800", "855", "866", "877", "888"]));
  		return this.optional(element) || jQuery.inArray(value, ["800", "855", "866", "877", "888"]) == -1;
	}, "This value is a TollFree NPA.");
	
	jQuery.validator.addMethod("city", function(value, element) {
  		return this.optional(element) || /^[a-zA-Z0-9,\-`\s]+$/.test(value);
	}, "This is an invalid city.");
	
	App.tfSearchFormHandler = (function($) {
		var timer;
		var init = function(is_admin) {
			validationOptions = {
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
				rules : {
					"search[carrier]" : {
						required: true
					},
					"search[wild_card]" : {
						required : true
					}
				},
				messages : {}
			}; 
			
			$("div#tf_search_result").on('click', '.number', function() {
				var number = $(this).html();
				if($(this).hasClass('btn-white')) {
					$(this).removeClass('btn-white unselect');
					$(this).addClass('btn-success select');
					$("#did_" + number).val(number).attr('disabled', false);
			    } 
			    else {
			    	$(this).addClass('btn-white unselect');
					$(this).removeClass('btn-success select');
					//Don't postback empty values on the server
					$("#did_" + number).val('').attr('disabled', true);
			    }
			    
			    $("a.tf_purchase_nos").trigger('set_disability');
			});

			$tfSearchFormValidator = $('#search_tf_nos_form').validate(validationOptions);
			
			$('form#search_tf_nos_form').on('ajax:beforeSend', function() {
				$("div#tf_search_result").removeClass('text-danger text-success').addClass('text-muted').html('Processing your request ' + ajax_loader);			
			})
			.on('ajax:error', function(e, xhr, status, error) {
				$("div#tf_search_result").removeClass('text-muted text-success').addClass('text-danger').html('Sorry, your request cannot be processed at the moment.');	
			});
			
			$('#reset_tf_search_form').click(function() {
				$('#search_tf_nos_form')[0].reset();
				$('#tf_wild_card, #select_tf_carrier').select2("val", "");
			});
			
			$("div#tf_search_result").on('click', '.result_select_all', function() {
				$("div#tf_search_result .number").not('.select').click();
				$("a.tf_purchase_nos").trigger('set_disability');
			});
			
			$("div#tf_search_result").on('click', '.result_deselect_all', function() {
				$("div#tf_search_result .number.select").click();
				$("a.tf_purchase_nos").trigger('set_disability');	
			});
			
			$("div#tf_search_result").on('click', '.result_invert_sel', function() {
				$("div#tf_search_result .number").click();
				$("a.tf_purchase_nos").trigger('set_disability');
			});
			
			$("div#tf_search_result").on('click', "a.tf_purchase_nos", function () {
				if($('a.number.select').length < 1) {
					return;
				}
				
				$("div#tf_search_result #time_left_for_order_conf").val($("div#tf_search_result #purchase_time_left").html())
				$(this).closest("form")[0].submit();					
			});
			
			$("div#tf_search_result").on('set_disability', 'a.tf_purchase_nos', function() {
				if($('div#tf_search_result a.number.select').length > 0) {
					$(this).removeClass('disabled');
				}
				else {
					$(this).addClass('disabled');
				}
			});
		};
		
		var startTimer = function(urls, timeout) {
			var startTime = new Date();
			var startTime = startTime.getMinutes() * 60 + startTime.getSeconds() + timeout; //timeout in seconds;
			
			clearInterval(timer);
				
			timer = setInterval(function () {
			     d = new Date(); //get current time
			    //convet current mm:ss to seconds for easier caculation, we don't care hours.
			     seconds = d.getMinutes() * 60 + d.getSeconds();
			    // let's say now is 01:30, then current seconds is 60+30 = 90. And 90%300 = 90, finally 300-90 = 210. That's the time left!
			     timeleft = startTime - seconds;
			    //formart seconds back into mm:ss 
			     result = leftPad(parseInt(timeleft / 60)) + ':' + leftPad(timeleft % 60);

			    if(result == '00:00') {
    				clearInterval(timer);
        			$("div#tf_search_result #purchase_time_left").addClass('text-danger').html('Oops! Time is out. You will be redirected to purchase page again.');
        			$("div#tf_search_result a.pur_button").addClass('disabled');
        			window.location.href = urls[0] + '?timeout=1';
        			return;
        		}
				
			    $("div#tf_search_result #purchase_time_left").html(result);

			}, 500);
		};				
		
		var leftPad = function (aNumber) { 
			return (aNumber < 10) ? "0" + aNumber : aNumber;
		};
		
		return {
			init: init,
			startTimer: startTimer
		};
	})(jQuery);
	
	App.LocalSearchFormHandler = (function($) {
		var urls, timer;

		var init = function(is_admin) {
			//$(".select2").select2({width: '100%'});
			//$("").select2({width: '100%'});
			$("#tf_wild_card, #search_city, #select_local_carrier, #select_tf_carrier").select2({width: '100%'});
			$("#search_state").select2({width: '100%'}).on("change", function() {
				$.getJSON(urls[0], {state: $(this).val()}, function(data) {
					var newOptions = '<option></option>';
					$.each(data, function(i, value) {
						newOptions += "<option>"+ value +"</option>";
					});
					$("#search_city").select2('destroy').html( newOptions ).select2({width: '100%'});
				});
			});

			if(is_admin) {
				initBillingRateDlg();
			}

			validationOptions = {
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
				rules : {
					"search[carrier]" : {
						required: true
					},
					"search[area_code]" : {
						required : function() {
							return $('#local_search_type').val() == "1";
						},
						digits: true,
						minlength: 3,
						maxlength: 3,
						areacodeStartRest: true,
						areacodeEndRest: true,
						areacodeMidRest: true,
						areacodeTFNpaRest: true
					},
					"search[city]": {
						required: function() {
							return $('#local_search_type').val() == "2";
						},
						city: true
					},
					"search[state]": {
						required: function() {
							return $('#local_search_type').val() == "2";
						}
					}
				},
				messages : {
					/*"carrier[account_code]" : {
						remote : "Account code already exists with us."
					},
					"carrier[company_name]" : {
						remote : "Company name already exists with us."
					},
					"carrier[user_attributes][email]" : {
						remote : "Email already exists with us."
					},
					"carrier[user_attributes][password_confirmation]": "This field should match the password."*/
				}
			}; 
			
			$localSearchFormValidator = $('#search_local_nos_form').validate(validationOptions);

			$("div#local_search_result").on('click', '.number', function() {
				var number = $(this).html();
				if($(this).hasClass('btn-white')) {
					$(this).removeClass('btn-white unselect');
					$(this).addClass('btn-success select');
					$("#did_" + number).val(number).attr('disabled', false);
			    } 
			    else {
			    	$(this).addClass('btn-white unselect');
					$(this).removeClass('btn-success select');
					//Don't postback empty values on the server
					$("#did_" + number).val('').attr('disabled', true);
			    }
			    
			    $("a.local_purchase_nos").trigger('set_disability');
			});
			
			$('form#search_local_nos_form').on('ajax:beforeSend', function() {
				$("div#local_search_result").removeClass('text-danger text-success').addClass('text-muted').html('Processing your request ' + ajax_loader);			
			})
			.on('ajax:error', function(e, xhr, status, error) {
				$("div#local_search_result").removeClass('text-muted text-success').addClass('text-danger').html('Sorry, your request cannot be processed at the moment.');	
			});
			
			$('#local_search_type').change(function() {
				var val = $(this).val();
				
				if(val == 1) {
					$('#search_area_code').val('');
					$('#city_container, #state_container').hide();
					$('#area_code_container').show();
				}		
				else {
					$('#search_state').select2("val", "");
					$('#search_city').val('');
					$('#city_container, #state_container').show();
					$('#area_code_container').hide();
				}
			});
			
			$('#reset_local_search_form').click(function() {
				$('#search_local_nos_form')[0].reset();
				$('#local_search_type').trigger('change');
				$('#search_state, #select_local_carrier').select2("val", "");
				$("#search_city").select2('destroy').html( '<option></option>' ).select2({width: '100%'});
			});
			
			$("div#local_search_result").on('click', '.result_select_all', function() {
				$("div#local_search_result .number").not('.select').click();
				$("a.local_purchase_nos").trigger('set_disability');
			});
			
			$("div#local_search_result").on('click', '.result_deselect_all', function() {
				$("div#local_search_result .number.select").click();
				$("a.local_purchase_nos").trigger('set_disability');	
			});
			
			$("div#local_search_result").on('click', '.result_invert_sel', function() {
				$("div#local_search_result .number").click();
				$("a.local_purchase_nos").trigger('set_disability');
			});
			
			$("div#local_search_result").on('click', "a.local_purchase_nos", function () {
				if($('a.number.select').length < 1) {
					return;
				}		
				$("#time_left_for_order_conf").val($("#purchase_time_left").html())
				$(this).closest("form")[0].submit();					
			});
			
			$("div#local_search_result").on('click', "input:checkbox", function () {
				$("a.local_purchase_nos").trigger('set_disability');
			});
			
			$("div#local_search_result").on('set_disability', 'a.local_purchase_nos', function() {
				if($('div#local_search_result a.number.select').length > 0) {
					$(this).removeClass('disabled');
				}			
				else {
					$(this).addClass('disabled');
				}
			});
		};

		var initBillingRateDlg = function() {
			$('#billing_rate_dlg').on('show.bs.modal', function (e) {
				var carrier_id = $('.tab-pane.active select.career_select').val();
  				if (!carrier_id) {
  					alert('Please select carrier to get billing rates.');
  					return e.preventDefault(); //stops modal from being shown
  				}; 

  				$.get('/carriers/' + carrier_id + '/billing_rates', {}, function(data) {
  					$('#billing_rate_dlg .modal-content').html(data);
  				});
			});
		};
		
		var setUrls = function(arr) {
			urls = arr;
		};
		
		var startTimer = function(urls, timeout) {
			var startTime = new Date();
			var startTime = startTime.getMinutes() * 60 + startTime.getSeconds() + timeout; //timeout in seconds;
			
			clearInterval(timer);
				
			timer = setInterval(function () {
			     d = new Date(); //get current time
			    //convet current mm:ss to seconds for easier caculation, we don't care hours.
			     seconds = d.getMinutes() * 60 + d.getSeconds();
			    // let's say now is 01:30, then current seconds is 60+30 = 90. And 90%300 = 90, finally 300-90 = 210. That's the time left!
			     timeleft = startTime - seconds;
			    //formart seconds back into mm:ss 
			     result = leftPad(parseInt(timeleft / 60)) + ':' + leftPad(timeleft % 60);

			    if(result == '00:00') {
    				clearInterval(timer);
        			$("div#local_search_result #purchase_time_left").addClass('text-danger').html('Oops! Time is out. You will be redirected to purchase page again.');
        			$("div#local_search_result a.pur_button").addClass('disabled');
        			window.location.href = urls[0] + '?timeout=1';
        			return;
        		}
				
			    $("div#local_search_result #purchase_time_left").html(result);

			}, 500);
		};		
		
	
		var leftPad = function (aNumber) { 
			return (aNumber < 10) ? "0" + aNumber : aNumber;
		};
		
		return {
			init: init,
			setUrls: setUrls,
			startTimer: startTimer
		};
	})(jQuery);
	
	App.InboundRateLocalFormHandler = (function($) {
		var init = function() {
			$("#submit_local_form").on('click', function() {
				App.RateSpinners.removeErrMsgsForLocal();	
				if(App.RateSpinners.validateLocalSpinners()) {
					disableActions();
					App.RateSpinners.removeErrMsgsForLocal();	
					$(this).parents('form').submit();
				}
				return false;	
			});
			
			$('form#edit_local_did_form').on('ajax:beforeSend', function() {
				App.RateSpinners.disableLocalSpinners();
				$("span#edit_local_did_form_msg").removeClass('text-danger text-success').addClass('text-muted').html('Processing your request ' + ajax_loader);			
			})
			.on('ajax:error', function(e, xhr, status, error) {
				App.RateSpinners.enableLocalSpinners();
				enableActions();	
				$("span#edit_local_did_form_msg").removeClass('text-muted text-success').addClass('text-danger').html('Sorry, your request cannot be processed at the moment.');	
			}).
			on('ajax:complete', function() {
				$("span#edit_local_did_form_msg").html('');
			});
			
			$("#reset_local_form").click(function() {
				App.RateSpinners.reset('local', [0,0,0,6,6]);
				App.RateSpinners.removeErrMsgsForLocal();
				return false;
			});
		};
		
		var enableActions = function() {
			$('#reset_local_form, #submit_local_form').attr('disabled', false);
		};
		
		var disableActions = function() {
			$('#reset_local_form, #submit_local_form').attr('disabled', true);
		};
		
		return {
			init: init,
			enableActions: enableActions,
			disableActions: disableActions
		};
			
	})(jQuery);
	
	App.InboundRateTollfreeFormHandler = (function($) {
		var init = function() {
			$("#submit_tf_form").on('click', function() {
				App.RateSpinners.removeErrMsgsForTollfree();
				
				if(App.RateSpinners.validateTollfreeSpinners()) {
					disableActions();
					$(this).parents('form').submit();
				}
				
				return false;	
			});
			
			$('form#edit_tollfree_did_form').on('ajax:beforeSend', function() {
				App.RateSpinners.disableTollfreeSpinners();
				$("span#edit_tf_did_form_msg").removeClass('text-danger text-success').addClass('text-muted').html('Processing your request ' + ajax_loader);			
			})
			.on('ajax:error', function(e, xhr, status, error) {
				App.RateSpinners.enableTollfreeSpinners();
				enableActions();
				$("span#edit_tf_did_form_msg").removeClass('text-muted text-success').addClass('text-danger').html('Sorry, your request cannot be processed at the moment.');	
			}).
			on('ajax:complete', function() {
				$("span#edit_tf_did_form_msg").html('');
			});
			
			$("#reset_tf_form").click(function() {
				App.RateSpinners.reset('tf', [0,0,0,6,6]);
				App.RateSpinners.removeErrMsgsForTollfree();
				return false;
			});
		};
		
		var enableActions = function() {
			$('#reset_tf_form, #submit_tf_form').attr('disabled', false);
		};
		
		var disableActions = function() {
			$('#reset_tf_form, #submit_tf_form').attr('disabled', true);
		};
		
		return {
			init: init,
			enableActions: enableActions,
			disableActions: disableActions
		};
			
	})(jQuery);

	App.AdminManageDidsHandler = (function($) {
		var urls;

		var init = function() {
			initEditDidDescription();
			initDatatable('.did_group');

			$(document).on('click', 'a.close_modal', function() {
				$(this).parents('.modal').modal('hide');
				$('input#release_reason, input#single_did').val('');
			});

			$("div.checkbox_toggler_container").on('click', '.result_select_all', function() {
				$("div#did_groups_container input.did-cb:checkbox:not(:checked)").attr('checked', true);	
				$("div#did_groups_container input.table-cb-toggler:not(:checked)").attr('checked', true);
				$('input.did-cb').parents('tr').addClass('checked');
				toggleGroupButtons();
			});
			
			$("div.checkbox_toggler_container").on('click', '.result_deselect_all', function() {
				$("div#did_groups_container input.did-cb:checkbox:checked").attr('checked', false);
				$("div#did_groups_container input.table-cb-toggler").attr('checked', false);
				$('input.did-cb').parents('tr').removeClass('checked');
				toggleGroupButtons();
			});
			
			$("div.checkbox_toggler_container").on('click', '.result_invert_sel', function() {
				$("div#did_groups_container input.did-cb:checkbox").click();
				$("div#did_groups_container input.table-cb-toggler").attr('checked', false);

				toggleGroupButtons();
			});

			$("div#did_groups_container").on('click', 'input.did-cb:checkbox', function() {
				toggleGroupButtons();
			});

			$("div#did_groups_container").on('click', 'input.did-cb', function() {
			    if ($(this).attr('checked')) {
			        $(this).parents('tr').addClass('checked');
			    } 
			    else {
			        $(this).parents('tr').removeClass('checked');
			    }
			});

			$("input.rel-reason").click(function() {
				var value = $(this).val();
				$('#release_other_reason').hide();
				
				if('other' == value) {
					$('input#release_reason, #release_other_reason').val('');
					$('#release_other_reason').show();
					$('#rel_did_confirm_ok').addClass('disabled');
				}
				else {
					$('input#release_reason').val(value);
					$('#rel_did_confirm_ok').removeClass('disabled');
				}
			});

			$("#release_other_reason").keyup(function() {
				var value = $(this).val();
				if($.trim(value) == '') {
					$('#rel_did_confirm_ok').addClass('disabled');
				}
				else {
					$('#rel_did_confirm_ok').removeClass('disabled');	
				}

				$('input#release_reason').val(value);
			});

			$('.release-did-confirm-dlg').on('show.bs.modal', function() {
				 var $form = $('form#selected_dids_form');	
				 $(this).find('form')[0].reset();
				 $('#rel_did_confirm_ok').addClass('disabled');
				 $('input#release_reason').val('');
				 $('#release_other_reason').hide();
				 $form.attr('action', urls[1]);
			});

			$('.remove-did-confirm-dlg').on('show.bs.modal', function() {
				 var $form = $('form#selected_dids_form');
				 $form.attr('action', urls[2]);
			});

			$('#rel_did_confirm_ok').click(function() {
				if('' == $.trim($('input#release_reason').val())) {
					return;
				}
				
				if($('#single_did').val() != '' || $("div#did_groups_container input.did-cb:checkbox:checked").length > 0) {
					$('form#selected_dids_form').submit();	
				}
			});

			$('#remove_did_confirm_ok').click(function() {
				if($('#single_did').val() != '' || $("div#did_groups_container input.did-cb:checkbox:checked").length > 0) {
					$('form#selected_dids_form').submit();
				}
			});

			$('#did_groups_container').on('click', '.release-link', function() {
				var id = $(this).data('pk');
				$('#single_did').val(id);
			});

			$('#did_groups_container').on('click', '.remove-link', function() {
				var id = $(this).data('pk');
				$('#single_did').val(id);
			});
		};

		var initEditDidDescription = function() {
			$('#did_groups_container').editable({
				toggle: 'click',
				selector: '.did-desc',
				validate: function(value) {
					if($.trim(value) === '')
						return 'Enter few words for description or cancel';
				},
				url: urls[0],
        		title: 'Update description',
        		rows: 5,
        		display: function(value) {
        			$(this).text(value.truncate(30));
        		},
        		ajaxOptions: {
        			type: 'put',

        		}
			});
		};

		var toggleGroupButtons = function() {
			if ($("div#did_groups_container input.did-cb:checkbox:checked").length > 0) {
				$('#btn_release_all, #btn_bulk_sms_settings, #btn_bulk_voice_settings, #btn_remove_all').removeClass('disabled');	
			}			
			else {
				$('#btn_release_all, #btn_bulk_sms_settings, #btn_bulk_voice_settings, #btn_remove_all').addClass('disabled');
			}
		};

		var initDatatable = function(selector) {
			$(selector).dataTable({
				resposive: true,
				"lengthMenu": [ [5, 10, 25, 50, 100, -1], [5, 10, 25, 50, 100, "All"] ],
				"displayLength": 25,
				"columnDefs":[{
			    	"targets" : 'no-sort',
			    	"orderable" : false,
			    }],
			    "language": {
					"paginate": {
						"previous": "<<",
						"next": ">>"
			        },
			        "search": ""
			    },
			    "fnDrawCallback": function() { 
			        var paginateRow = $(this).parent().children('div.dataTables_paginate');
			        var pageCount = Math.ceil((this.fnSettings().fnRecordsDisplay()) / this.fnSettings()._iDisplayLength);
			         
			        if (pageCount > 1)  {
			            paginateRow.css("display", "block");
			        } else {
			            paginateRow.css("display", "none");
			        }

			        $(this).find('.table-cb-toggler, input.did-cb:checkbox').attr('checked', false);
			        toggleGroupButtons();
			    }
			});
		};

		var setUrls = function(arr) {
			urls = arr;
		};

		return {
			init: init,
			setUrls: setUrls
		};
	})(jQuery);
	
});