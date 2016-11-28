//= require bootstrap.min
//= require modernizr.min
//= require toggles.min
//= require retina.min
//= require jquery.cookies
//= require jquery.gritter.min
//= require bootstrap-wizard.min
//= require jquery.gritter.min
//= require select2.min
//= require jquery_nested_form
//= require jquery.validate.min
//= require jquery.datatables.min
//= require custom
//= require_self

var App = App || {};

$(document).ready(function() {
	App.AdminIngressTrunkFormHandler = (function($) {
		var urls; 
		var $call_limit_spinner, $cps_limit_spinner, $profit_margin_value_spinner,
			$profit_margin_pc_spinner, $try_timeout_spinner, $pdd_timeout_spinner,
			$ring_timeout_spinner, $decimal_points_spinner, $max_duration_spinner,
			$max_cost_spinner;

		var init = function(toggleStatuses) {
  			$(".select2").select2({
    			width: '75%'
  			});

  			$("#ingress_trunk_carrier_id").select2({
  				width: '75%',
  			}).on('change', function() {
  				var val = $(this).val();
  				
  				$.get(urls[4], {'carrier_id': val}, function(data) {
  					$('#ingress_trunk_reg_user').val(data);
  				}, 'html');
  			});

  			$("#ingress_trunk_profit_margin_type").select2({
  				width: '75%',
  			}).on('change', function() {
  				var val = $(this).val();
  				
  				if(val == '0') {
  					$('label#profit_margin_type_msg').hide();
  					$('#profit_margin_value_cont').show();
  					$('#profit_margin_pc_cont').hide();
  				}
  				else if(val == '1') {
  					$('label#profit_margin_type_msg').hide();
  					$('#profit_margin_value_cont').hide();
  					$('#profit_margin_pc_cont').show();
  				}
  				else {
  					$('label#profit_margin_type_msg').show();
  					$('#profit_margin_value_cont').hide();
  					$('#profit_margin_pc_cont').hide();
  				}
  			});

  			$('#ingress_trunk_ingress_type').select2({
  				width: '75%'
  			}).on('change', function() {
  				var val = $(this).val();

  				if(val == '0') {
  					$('span#registration_fields').show();
  					$('span#ip_auth_fields').hide();
  				}
  				else if(val == '1') {
  					$('span#registration_fields').hide();
  					$('span#ip_auth_fields').show();
  				}
  				else {
  					$('span#registration_fields').hide();
  					$('span#ip_auth_fields').hide();
  				}
  			});

  			$(document).on('nested:fieldRemoved', function(event){
				event.field.removeClass('fields');
				
				$('.add_nested_fields').removeClass('disabled');
				
				if($('div.fields').filter(":visible").length < 1) {
					$('table#host_headings').hide();
					$('div#add_host_warning').show();
				}
  			});

  			$(document).on('nested:fieldAdded', function(event){
  				if($("span#ip_auth_fields .fields").length >= 12) {
  					$('.add_nested_fields').addClass('disabled');
  				}

				$('table#host_headings').show();
				$('div#add_host_warning').hide();
				$('.tooltips').tooltip({ container: 'body'});
  			});

  			$('.generate_random').click( function(){
    			$(this).siblings('.form-control').val(randomAlphaString(10));
  			});

  			$('.cancel-form').click(function(e) {
  				window.location.href = urls[0];
  				return false;
  			});

  			$call_limit_spinner = $('#call_limit_spinner').spinner({
				numberFormat: "n",
				step: 10,
				min: 0,
				max: 10000,
				value: 0
			});

			$cps_limit_spinner = $('#cps_limit_spinner').spinner({
				numberFormat: "n",
				step: 5,
				min: 0,
				max: 500,
				value: 0
			});

			$profit_margin_value_spinner = $('#profit_margin_value_spinner').spinner({
				numberFormat: "n",
				step: 1,
				min: -500,
				max: 500,
				value: 0
			});

			$profit_margin_pc_spinner = $('#profit_margin_pc_spinner').spinner({
				numberFormat: "n",
				step: 0.01,
				min: -1,
				max: 1,
				value: 0
			});

			$try_timeout_spinner = $('#try_timeout_spinner').spinner({
				numberFormat: "n",
				step: 1,
				min: 1,
				max: 60,
				value: 2
			});

			$pdd_timeout_spinner = $('#pdd_timeout_spinner').spinner({
				numberFormat: "n",
				step: 1,
				min: 1,
				max: 60,
				value: 6
			});

			$ring_timeout_spinner = $('#ring_timeout_spinner').spinner({
				numberFormat: "n",
				step: 1,
				min: 1,
				max: 120,
				value: 60
			});

			$decimal_points_spinner = $('#decimal_points_spinner').spinner({
				numberFormat: "n",
				step: 1,
				min: 2,
				max: 8,
				value: 4
			});

			$max_duration_spinner = $('#max_duration_spinner').spinner({
				numberFormat: "n",
				step: 100,
				min: 60,
				max: 7200,
				value: 7200
			});

			$max_cost_spinner = $('#max_cost_spinner').spinner({
				numberFormat: "n",
				step: 0.01,
				min: 0,
				max: 1,
				value: 0
			});

			$("#siptrace_activation_tgl").toggles({ on: toggleStatuses[0], checkbox: $("#sip_trace_tgl_chkbox"), 'event': 'toggle', text: {on: "Yes", off: "No"}});
			$("#media_bypass_activation_tgl").toggles({ on: toggleStatuses[1], checkbox: $("#media_bypass_tgl_chkbox"), 'event': 'toggle', text: {on: "Yes", off: "No"}});
			$("#lrn_block_activation_tgl").toggles({ on: toggleStatuses[2], checkbox: $("#lrn_block_tgl_chkbox"), 'event': 'toggle', text: {on: "Yes", off: "No"}});
			$("#block_wireless_activation_tgl").toggles({ on: toggleStatuses[3], checkbox: $("#block_wireless_tgl_chkbox"), 'event': 'toggle', text: {on: "Yes", off: "No"}});

			$.validator.addMethod("cid", function(value, element) {
				return this.optional(element) || /^[\d\+]+$/.test(value);
			}, "Only digits and '+' sign is allowed");

			$.validator.addMethod("techprefix", function(value, element) {
				return this.optional(element) || /^[\d#]+$/.test(value);
			}, "Only digits and '#' is allowed");

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
					if (validateSpinners() && validateIPAuthentication()) {
						form.submit();
					}
				},
				errorPlacement: function(error, element) {
					if (element.attr("id") == "ingress_trunk_reg_user") {
						$("#rgn_username_error").html(error);
				    }
				    else if(element.attr("id") == "ingress_trunk_reg_password") {
				    	$("#rgn_password_error").html(error);
				    }
				    else {
				        // the default error placement for the rest
				        error.insertAfter(element);
				    }
				},
				rules : {
					"ingress_trunk[carrier_id]": {
						required: true,
						digits: true
					},
					"ingress_trunk[routing_id]": {
						required: true,
						digits: true
					},
					"ingress_trunk[rate_sheet_id]": {
						required: true,
						digits: true
					},
					"ingress_trunk[tech_prefix]": {
						techprefix: true
					},
					"ingress_trunk[reg_user]": {
						required: function() {
							return $('#ingress_trunk_ingress_type').val() == '0'
						},
						minlength: 5,
						maxlength: 25,
						remote : {
							url : urls[3],
							type : "get"
						}
					},
					"ingress_trunk[reg_password]": {
						required: function() {
							return $('#ingress_trunk_ingress_type').val() == '0'
						},
						minlength: 5,
						maxlength: 25
					},
					"ingress_trunk[profit_margin_type]": {
						required: true,
						digits: true
					},
					"ingress_trunk[force_cid]": {
						cid: true
					},
					"ingress_trunk[name]" : {
						required : true,
						minlength: 3,
						maxlength: 25,
						remote : {
							url : urls[1],
							type : "get",
						}
					}
				},
				messages : {
					"ingress_trunk[name]" : {
						remote : "This trunk name already exists with us."
					},
					"ingress_trunk[reg_user]" : {
						remote : "This username already exists with us."
					}
				}
			};

			$editFormValidator = $('#editIngressTrunkForm').validate($.extend(true, {}, validationOptions, {
				rules: {
					"ingress_trunk[name]": {remote: {
						data: {id: $('#ingress_trunk_id').val()}
					}},
					"ingress_trunk[reg_user]": {remote: {
						data: {id: $('#ingress_trunk_id').val()}
					}}
				}
			}));
			
			$newFormValidator = $('#newIngressTrunkForm').validate($.extend(true, {}, validationOptions, {}));

			$('#editIngressTrunkWizard').bootstrapWizard({
				'nextSelector' : '.next',
				'previousSelector' : '.previous',

				onNext : function(tab, navigation, index) {
					if(index == 2) return true;

					return validateEditForm() && validateIPAuthentication();
				},
				onPrevious : function(tab, navigation, index) {
					return validateEditForm() && validateSpinners();
				},
				onTabClick: function(tab, navigation, index) {
					return validateEditForm() && validateSpinners() && validateIPAuthentication();
				}
			});

  			$('#newIngressTrunkWizard').bootstrapWizard({
				'nextSelector' : '.next',
				'previousSelector' : '.previous',
				onNext : function(tab, navigation, index) {
					if(index == 2) return true;

					$('#newFormFinishBtn').addClass('disabled');
					
					if(validateNewForm() && validateSpinners() && validateIPAuthentication()) {
						if (index == 1) {
							$('#newFormFinishBtn').removeClass('disabled');
						}
						
						return true;
					}
					
					return false;
				},
				onPrevious : function(tab, navigation, index) {
					$('#newFormFinishBtn').addClass('disabled');
					return true;
				},
				onTabClick: function(tab, navigation, index) {
					return false;
    			}
			});
		};

		var validateSpinners = function() {
			var isValid = true;
			$.each([$call_limit_spinner, $cps_limit_spinner, $profit_margin_value_spinner,
					$profit_margin_pc_spinner, $try_timeout_spinner, $pdd_timeout_spinner,
					$ring_timeout_spinner, $decimal_points_spinner, $max_duration_spinner,
					$max_cost_spinner], function(i, $el) {

				var errorMsg = '';
				var value = $el.spinner("value");
				var min = $el.spinner("option", "min");
				var max = $el.spinner("option", "max");
				var id = $el.attr('id');
				
				if($el.is(':visible')) {
					if(value == null){
						errorMsg = 'Please input a number.';
						isValid = false;	
					}
					else if($.inArray(i, [0, 1, 4, 5, 6, 7, 8]) >= 0 && /\D/.test(value)) {
						errorMsg = 'Please input a integer value.';
						isValid = false;	
					}
					else if(i == 2 && !(/^\-?[0-9]+$/.test(value))) {
						errorMsg = 'Please input a integer value.';
						isValid = false;	
					}
					else {
						if(value < min || value > max) {
							errorMsg = 'Please select the value that lie between ' +  min + ' to ' + max + '.';
							isValid = false;
						}	
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
		}

		var validateIPAuthentication = function() {
			if($('#ingress_trunk_ingress_type').val() != '1') return true;
			
			var error = false;
			var postData = new Array();
			
			if($("span#ip_auth_fields .fields").length < 1) {
				$('.settings-err-msg').html('Please add atleast one host.').show();
				return false;
			}

			$("span#ip_auth_fields .fields").each(function() {
				$('.settings-err-msg').hide();

				$ip_address = $(this).find('.ip_address');
				$subnet = $(this).find('.subnet');
				$port = $(this).find('.port');

				postData.push([$ip_address.val(), $subnet.val(), $port.val()]);
				
				$ip_address.removeClass('settings-error');
				$subnet.removeClass('settings-error');
				$port.removeClass('settings-error');

				if($.trim($ip_address.val()) == '' || !( /^(([1-9]?\d|1\d\d|2[0-5][0-5]|2[0-4]\d)\.){3}([1-9]?\d|1\d\d|2[0-5][0-5]|2[0-4]\d)$/i.test($ip_address.val()))) {
					$ip_address.addClass('settings-error');
					error = true;
				}

				if($.trim($subnet.val()) == '' || !(/^\d+$/.test($subnet.val())) || parseInt($subnet.val()) < 0 || parseInt($subnet.val()) > 32) {
					$subnet.addClass('settings-error');
					error = true;
				}

				if($.trim($port.val()) == '' || !(/^\d+$/.test($port.val())) || parseInt($port.val()) < 0 || parseInt($port.val()) > 65535) {
					$port.addClass('settings-error');
					error = true;
				}
			});

			if(error) {
				$('.settings-err-msg').html('Please fix the error(s) for field(s) marked in red. Hover over fields to check valid values.').show();
			}
			else {
				$.ajax({
			        type: "POST",
			        async: false,
			        url: urls[2],
			        data: {'data': postData, 'id': $('#ingress_trunk_id').val()},
			        dataType: 'json',
			        success: function(response) {
			        	if(response.length == 0) {
			        		error = false;
			        	}
			        	else {
			        		$('.settings-err-msg').html('Row(s) '+ response.join(', ') +' already exists with us. The combination of Host, Subnet and Port should be unique.').show();
			        		error = true;	
			        	}
			        },
			        error: function() {
			        	error = true;
			        }
			    });
			}

			return !error;
		};

		var validateNewForm = function() {
			var $valid = $('#newIngressTrunkForm').valid();
					
			if (!$valid) {
				$newFormValidator.focusInvalid();
				return false;
			}
			
			return true;
		};

		var validateEditForm = function() {
			var $valid = $('#editIngressTrunkForm').valid();
					
			if (!$valid) {
				$editFormValidator.focusInvalid();
				return false;
			}
			
			return true;
		};

		var resetSpinnersTo = function(values) {
			$call_limit_spinner.spinner("value", values[0]);
			$cps_limit_spinner.spinner("value", values[1]);
			$profit_margin_value_spinner.spinner("value", values[2]);
			$profit_margin_pc_spinner.spinner("value", values[3]);
			$try_timeout_spinner.spinner("value", values[4]);
			$pdd_timeout_spinner.spinner("value", values[5]);
			$ring_timeout_spinner.spinner("value", values[6]);
			$decimal_points_spinner.spinner("value", values[7]);
			$max_duration_spinner.spinner("value", values[8]);
			$max_cost_spinner.spinner("value", values[9]);
		};

		var setUrls = function(arr) {
			urls = arr;
		}

		return {
			init: init,
			setUrls: setUrls,
			resetSpinnersTo: resetSpinnersTo
		};
			
	})(jQuery);

	App.AdminIngressTrunkListHandler = (function($) {
		var urls, destroy_trunk, disable_trunk, enable_trunk,
			bulk_operation = false; 

		var init = function(options) {
			$(document).on('click', 'a.close_modal', function() {
				$(this).parents('.modal').modal('hide');					
				bulk_operation = false;
			});

			$("#carrier_select").select2({
  				width: '225px'
  			}).on('change', function() {
				$('#ingress_trunks_table').DataTable().columns(2).search($(this).val()).draw();
  			});

  			if(options[0] > 0) {
  				$("#carrier_select").select2('val', options[0]);
  			}

			$("div.checkbox_toggler_container").on('click', '.result_select_all', function() {
				$("div.ingress-trunks-container input.trunk-cb:checkbox:not(:checked)").attr('checked', true);	
				toggleGroupButtons();
			});
			
			$("div.checkbox_toggler_container").on('click', '.result_deselect_all', function() {
				$("div.ingress-trunks-container input.trunk-cb:checkbox:checked").attr('checked', false);
				toggleGroupButtons();
			});
			
			$("div.checkbox_toggler_container").on('click', '.result_invert_sel', function() {
				$("div.ingress-trunks-container input.trunk-cb:checkbox").click();
				toggleGroupButtons();
			});

			$("div.ingress-trunks-container").on('click', 'input.trunk-cb:checkbox', function() {
				toggleGroupButtons();
			});

			$('table#ingress_trunks_table').on('click', '.trunk_destroy', function() {
				destroy_trunk = $(this).data('trunk-id');

				$('.delete-trunk-confirm-dlg').modal('show');

				return false;
			});

			$('#del_trunk_confirm_ok').click(function () {
				if(bulk_operation) {
					$('form#selected_trunks_form').submit();
				}
				else {
					var link = "a#trunk_" + destroy_trunk + "_destroy_link";
					$(link).click();
				}
				
				$('.delete-trunk-confirm-dlg').modal('hide');
				bulk_operation = false;
			});

			$('table#ingress_trunks_table').on('click', '.trunk_disable', function() {
				disable_trunk = $(this).data('trunk-id');

				$('.disable-trunk-confirm-dlg').modal('show');

				return false;
			});

			$('#disable_trunk_confirm_ok').click(function () {
				if(bulk_operation) {
					$('form#selected_trunks_form').submit();
				}
				else {
					var link = "a#trunk_" + disable_trunk + "_disable_link";
					$(link).click();	
				}
				
				$('.disable-trunk-confirm-dlg').modal('hide');
				bulk_operation = false;
			});

			$('table#ingress_trunks_table').on('click', '.trunk_enable', function() {
				enable_trunk = $(this).data('trunk-id');

				$('.enable-trunk-confirm-dlg').modal('show');

				return false;
			});

			$('#enable_trunk_confirm_ok').click(function () {
				if(bulk_operation) {
					$('form#selected_trunks_form').submit();
				}
				else {
					var link = "a#trunk_" + enable_trunk + "_enable_link";
					$(link).click();
				}

				$('.enable-trunk-confirm-dlg').modal('hide');
				bulk_operation = false;
			});

			$('button.btn_change_all_status').click(function() {
				bulk_operation = true;
				$('form#selected_trunks_form').attr('action', $(this).data('url'));
			});

			$('#ingress_trunks_table').DataTable({
				resposive: true,
				/*"sDom": '<"top"l>rt<"bottom"ip><"clear">',*/
				"lengthMenu": [ [5, 10, 25, 50, 100, -1], [5, 10, 25, 50, 100, "All"] ],
				"displayLength": 25,
				"columnDefs":[
					{
			    	"targets" : 'no-sort',
			    	"orderable" : false,
			    	},
			    	{
				    	"targets": 0,
				    	"createdCell": function (td, cellData, rowData, row, col) {
							$(td).addClass('text-center').html('<input type="checkbox" name="ingress_trunk_ids[]" class="trunk-cb" value="'+ cellData +'">');
						}
					},
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
							if(cellData[4]) {
								if(cellData[0]) {
									innerHtml += ' <a href="#" rel="nofollow" data-trunk-id="'+ rowData[0] +'" title="Deactivate" class="btn btn-warning btn-xs trunk_disable"><span class="glyphicon glyphicon-lock"></a> ';
									innerHtml += ' <a href="/ingress_trunks/'+ rowData[0] +'/deactivate" rel="nofollow" data-remote="true" data-method="put" id="trunk_'+ rowData[0] +'_disable_link"></a>';	
								}
							}
							else {
								if(cellData[1]) {
									innerHtml += ' <a href="#" rel="nofollow" data-trunk-id="'+ rowData[0] +'" title="Activate" class="btn btn-primary btn-xs trunk_enable"><span class="glyphicon glyphicon-check"></a> ';
									innerHtml += ' <a href="/ingress_trunks/'+ rowData[0] +'/activate" rel="nofollow" data-remote="true" data-method="put" id="trunk_'+ rowData[0] +'_enable_link"></a>';	
								}
								
							}
							
							if(cellData[2]) {
								innerHtml += ' <a class="btn btn-default btn-xs" title="Modify" href="/ingress_trunks/'+ rowData[0] +'/edit"><span class="glyphicon glyphicon-edit"></span></a>';	
							}
							
							if(cellData[3]) {
								innerHtml += ' <a href="#" rel="nofollow" data-trunk-id="'+ rowData[0] +'" title="Delete" class="btn btn-danger btn-xs trunk_destroy"><span class="glyphicon glyphicon-trash"></span></a> ';
								innerHtml += ' <a href="/ingress_trunks/'+ rowData[0] +'" rel="nofollow" data-remote="true" data-method="delete" id="trunk_'+ rowData[0] +'_destroy_link"></a>';	
							}
							
				    		$(td).html(innerHtml);
						}
					}
				],
			    "order": [[ 1, "desc" ]],
			    "processing": true,
			    "serverSide": true,
			    "deferLoading": true,
			    "ajax": {
			    	url: urls[0],
			    	method: 'post',
			    	data: {
			    		page: function() {
			    			return $('#ingress_trunks_table').DataTable().page.info().page + 1;
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

			        $(this).find('input.trunk-cb:checkbox').attr('checked', false);
			        toggleGroupButtons();
			    }
			});
		};

		var toggleGroupButtons = function() {
			if ($("div.ingress-trunks-container input.trunk-cb:checkbox:checked").length > 0) {
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

	App.CarrierIngressTrunkFormHandler = (function($) {
		var urls, dirtyValues;
		var $call_limit_spinner, $cps_limit_spinner;

		var init = function(toggleStatuses) {
  			$(".select2").select2({
    			width: '75%'
  			});

  			$('span#ip_auth_fields').on('keyup', 'input[type="text"]', function() {
  				console.log('Values changed...');
  				dirtyValues[3] = true;
  			});

  			$('#ingress_trunk_ingress_type').select2({
  				width: '75%'
  			}).on('change', function() {
  				var val = $(this).val();

  				if(val == '0') {
  					$('span#registration_fields').show();
  					$('span#ip_auth_fields').hide();
  				}
  				else if(val == '1') {
  					$('span#registration_fields').hide();
  					$('span#ip_auth_fields').show();
  				}
  				else {
  					$('span#registration_fields').hide();
  					$('span#ip_auth_fields').hide();
  				}
  			});

  			$(document).on('nested:fieldRemoved', function(event){
				event.field.removeClass('fields');
				
				$('.add_nested_fields').removeClass('disabled');
				
				if($('div.fields').filter(":visible").length < 1) {
					$('table#host_headings').hide();
					$('div#add_host_warning').show();
				}

				dirtyValues[3] = true;
  			});

  			$(document).on('nested:fieldAdded', function(event){
  				if($("span#ip_auth_fields .fields").length >= 12) {
  					$('.add_nested_fields').addClass('disabled');
  				}

				$('table#host_headings').show();
				$('div#add_host_warning').hide();
				$('.tooltips').tooltip({ container: 'body'});

				dirtyValues[3] = true;
  			});

  			$('.generate_random').click( function(){
    			$(this).siblings('.form-control').val(randomAlphaString(10));
  			});

  			$('.cancel-form').click(function(e) {
  				window.location.href = urls[0];
  				return false;
  			});

  			$call_limit_spinner = $('#call_limit_spinner').spinner({
				numberFormat: "n",
				step: 10,
				min: 0,
				max: 10000,
				value: 0
			}).spinner('disable');

			$cps_limit_spinner = $('#cps_limit_spinner').spinner({
				numberFormat: "n",
				step: 5,
				min: 0,
				max: 500,
				value: 0
			}).spinner('disable');

			$("#media_bypass_activation_tgl").toggles({ on: toggleStatuses[1], checkbox: $("#media_bypass_tgl_chkbox"), 'event': 'toggle', text: {on: "Yes", off: "No"}});
			$("#lrn_block_activation_tgl").toggles({ drag:false, click: false, on: toggleStatuses[2], 'event': 'toggle', text: {on: "Yes", off: "No"}});
			$("#block_wireless_activation_tgl").toggles({ on: toggleStatuses[3], checkbox: $("#block_wireless_tgl_chkbox"), 'event': 'toggle', text: {on: "Yes", off: "No"}});

			$.validator.addMethod("cid", function(value, element) {
				return this.optional(element) || /^[\d\+]+$/.test(value);
			}, "Only digits and '+' sign is allowed");

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
					if (validateIPAuthentication()) {
						if(otpAuthRequired()) {
							App.OTPAuth.showDialog('trunk_update', function() {
								$('#otpid').val(App.OTPAuth.getOTPId());
								$('#otpcode').val(App.OTPAuth.getOTPCode());			
								form.submit();
							});
						}
						else {
							form.submit();	
						}
					}
				},
				errorPlacement: function(error, element) {
					if (element.attr("id") == "ingress_trunk_reg_user") {
						$("#rgn_username_error").html(error);
				    }
				    else if(element.attr("id") == "ingress_trunk_reg_password") {
				    	$("#rgn_password_error").html(error);
				    }
				    else {
				        // the default error placement for the re
				        error.insertAfter(element);
				    }
				},
				rules : {
					"ingress_trunk[reg_user]": {
						required: function() {
							return $('#ingress_trunk_ingress_type').val() == '0'
						},
						minlength: 5,
						maxlength: 25,
						remote : {
							url : urls[3],
							type : "get"
						}
					},
					"ingress_trunk[reg_password]": {
						required: function() {
							return $('#ingress_trunk_ingress_type').val() == '0'
						},
						minlength: 5,
						maxlength: 25
					},
					"ingress_trunk[force_cid]": {
						cid: true
					}
				},
				messages : {
					"ingress_trunk[reg_user]" : {
						remote : "This username already exists with us."
					}
				}
			};

			$editFormValidator = $('#editIngressTrunkForm').validate($.extend(true, {}, validationOptions, {
				rules: {
					"ingress_trunk[reg_user]": {remote: {
						data: {id: $('#ingress_trunk_id').val()}
					}}
				}
			}));

			$('#editIngressTrunkWizard').bootstrapWizard({
				'nextSelector' : '.next',
				'previousSelector' : '.previous',

				onNext : function(tab, navigation, index) {
					if(index == 2) return true;

					return validateEditForm() && validateIPAuthentication();
				},
				onPrevious : function(tab, navigation, index) {
					return validateEditForm();
				},
				onTabClick: function(tab, navigation, index) {
					return validateEditForm() && validateIPAuthentication();
				}
			});
		};

		var otpAuthRequired = function() {
			if($('#ingress_trunk_ingress_type').val() != dirtyValues[0]) {
				console.log('ingress type changed.');
				return true;
			}

			if($('#ingress_trunk_ingress_type').val() == '0') {
				if($.trim($('#ingress_trunk_reg_user').val()) != dirtyValues[1]) {
					console.log('username is changed.');
					return true;
				}

				if($.trim($('#ingress_trunk_reg_password').val()) != dirtyValues[2]) {
					console.log('password is changed.');
					return true;
				}				
			}
			else {
				if(dirtyValues[3]) {
					console.log('host changed.');
					return true;
				}
			}

			return false;
		}

		var setDirtyValues = function(values) {
			dirtyValues = values;
		}

		var validateIPAuthentication = function() {
			if($('#ingress_trunk_ingress_type').val() != '1') return true;
			
			var error = false;
			var postData = new Array();
			
			if($("span#ip_auth_fields .fields").length < 1) {
				$('.settings-err-msg').html('Please add atleast one host.').show();
				return false;
			}

			$("span#ip_auth_fields .fields").each(function() {
				$('.settings-err-msg').hide();

				$ip_address = $(this).find('.ip_address');
				$subnet = $(this).find('.subnet');
				$port = $(this).find('.port');

				postData.push([$ip_address.val(), $subnet.val(), $port.val()]);
				
				$ip_address.removeClass('settings-error');
				$subnet.removeClass('settings-error');
				$port.removeClass('settings-error');

				if($.trim($ip_address.val()) == '' || !( /^(([1-9]?\d|1\d\d|2[0-5][0-5]|2[0-4]\d)\.){3}([1-9]?\d|1\d\d|2[0-5][0-5]|2[0-4]\d)$/i.test($ip_address.val()))) {
					$ip_address.addClass('settings-error');
					error = true;
				}

				if($.trim($subnet.val()) == '' || !(/^\d+$/.test($subnet.val())) || parseInt($subnet.val()) < 0 || parseInt($subnet.val()) > 32) {
					$subnet.addClass('settings-error');
					error = true;
				}
				
				if($.trim($port.val()) == '' || !(/^\d+$/.test($port.val())) || parseInt($port.val()) < 0 || parseInt($port.val()) > 65535) {
					$port.addClass('settings-error');
					error = true;
				}
			});

			if(error) {
				$('.settings-err-msg').html('Please fix the error(s) for field(s) marked in red. Hover over fields to check valid values.').show();
			}
			else {
				$.ajax({
			        type: "POST",
			        async: false,
			        url: urls[2],
			        data: {'data': postData, 'id': $('#ingress_trunk_id').val()},
			        dataType: 'json',
			        success: function(response) {
			        	if(response.length == 0) {
			        		error = false;
			        	}
			        	else {
			        		$('.settings-err-msg').html('Row(s) '+ response.join(', ') +' already exists with us. The combination of Host, Subnet and Port should be unique.').show();
			        		error = true;	
			        	}
			        },
			        error: function() {
			        	error = true;
			        }
			    });
			}

			return !error;
		};

		var validateEditForm = function() {
			var $valid = $('#editIngressTrunkForm').valid();
					
			if (!$valid) {
				$editFormValidator.focusInvalid();
				return false;
			}
			
			return true;
		};

		var resetSpinnersTo = function(values) {
			$call_limit_spinner.spinner("value", values[0]);
			$cps_limit_spinner.spinner("value", values[1]);
		};

		var setUrls = function(arr) {
			urls = arr;
		}

		return {
			init: init,
			setUrls: setUrls,
			resetSpinnersTo: resetSpinnersTo,
			setDirtyValues: setDirtyValues
		};
			
	})(jQuery);

	App.CarrierIngressTrunkListHandler = (function($) {
		var urls, destroy_trunk, disable_trunk, enable_trunk,
			bulk_operation = false;

		var init = function(toggleStatuses) {
			$(document).on('click', 'a.close_modal', function() {
				$(this).parents('.modal').modal('hide');					
				bulk_operation = false;
			});

			$("div.checkbox_toggler_container").on('click', '.result_select_all', function() {
				$("div.ingress-trunks-container input.trunk-cb:checkbox:not(:checked)").attr('checked', true);	
				toggleGroupButtons();
			});
			
			$("div.checkbox_toggler_container").on('click', '.result_deselect_all', function() {
				$("div.ingress-trunks-container input.trunk-cb:checkbox:checked").attr('checked', false);
				toggleGroupButtons();
			});
			
			$("div.checkbox_toggler_container").on('click', '.result_invert_sel', function() {
				$("div.ingress-trunks-container input.trunk-cb:checkbox").click();
				toggleGroupButtons();
			});

			$("div.ingress-trunks-container").on('click', 'input.trunk-cb:checkbox', function() {
				toggleGroupButtons();
			});

			$('table#ingress_trunks_table').on('click', '.trunk_disable', function() {
				disable_trunk = $(this).data('trunk-id');

				$('.disable-trunk-confirm-dlg').modal('show');

				return false;
			});

			$('#disable_trunk_confirm_ok').click(function () {
				if(bulk_operation) {
					App.OTPAuth.showDialog('trunk_bulk_actdeact', function() {
						$('#otpid').val(App.OTPAuth.getOTPId());
						$('#otpcode').val(App.OTPAuth.getOTPCode());					
						$('form#selected_trunks_form').submit();
						App.OTPAuth.hideDialog();
					});
				}
				else {
					var link = "a#trunk_" + disable_trunk + "_disable_link";

					App.OTPAuth.showDialog('trunk_act_deact', function() {
						var data = {otpid: App.OTPAuth.getOTPId(), 
									otpcode: App.OTPAuth.getOTPCode()};
				    
						$(link).attr('href', $(link).attr('href') + "?" + jQuery.param(data));
				    	$(link).click();
					
						App.OTPAuth.hideDialog();
					});
				}
				
				$('.disable-trunk-confirm-dlg').modal('hide');
				bulk_operation = false;
			});

			$('table#ingress_trunks_table').on('click', '.trunk_enable', function() {
				enable_trunk = $(this).data('trunk-id');

				$('.enable-trunk-confirm-dlg').modal('show');

				return false;
			});

			$('#enable_trunk_confirm_ok').click(function () {
				if(bulk_operation) {
					App.OTPAuth.showDialog('trunk_bulk_actdeact', function() {
						$('#otpid').val(App.OTPAuth.getOTPId());
						$('#otpcode').val(App.OTPAuth.getOTPCode());					
						$('form#selected_trunks_form').submit();
						App.OTPAuth.hideDialog();
					});
				}
				else {
					var link = "a#trunk_" + enable_trunk + "_enable_link";
					App.OTPAuth.showDialog('trunk_act_deact', function() {
						var data = {otpid: App.OTPAuth.getOTPId(), 
									otpcode: App.OTPAuth.getOTPCode()};
				    
						$(link).attr('href', $(link).attr('href') + "?" + jQuery.param(data));
				    	$(link).click();
					
						App.OTPAuth.hideDialog();
					});
				}

				$('.enable-trunk-confirm-dlg').modal('hide');
				bulk_operation = false;
			});

			$('button.btn_change_all_status').click(function() {
				bulk_operation = true;
				$('form#selected_trunks_form').attr('action', $(this).data('url'));
			});

			$('#ingress_trunks_table').DataTable({
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
							$(td).addClass('text-center').html('<input type="checkbox" name="ingress_trunk_ids[]" class="trunk-cb" value="'+ cellData +'">');
						}
					},
					{
				    	"targets": 4,
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
						"targets": 5,
						"createdCell": function (td, cellData, rowData, row, col) {
							innerHtml = '';
							if(cellData[3]) {
								if(cellData[0]) {
									innerHtml += ' <a href="#" rel="nofollow" data-trunk-id="'+ rowData[0] +'" title="Deactivate" class="btn btn-warning btn-xs trunk_disable"><span class="glyphicon glyphicon-lock"></a> ';
									innerHtml += ' <a href="/ingress_trunks/'+ rowData[0] +'/deactivate" rel="nofollow" data-remote="true" data-method="put" id="trunk_'+ rowData[0] +'_disable_link"></a>';	
								}
							}
							else {
								if(cellData[1]) {
									innerHtml += ' <a href="#" rel="nofollow" data-trunk-id="'+ rowData[0] +'" title="Activate" class="btn btn-primary btn-xs trunk_enable"><span class="glyphicon glyphicon-check"></a> ';
									innerHtml += ' <a href="/ingress_trunks/'+ rowData[0] +'/activate" rel="nofollow" data-remote="true" data-method="put" id="trunk_'+ rowData[0] +'_enable_link"></a>';	
								}
							}
							
							if(cellData[2]) {
								innerHtml += ' <a class="btn btn-default btn-xs" title="Modify" href="/ingress_trunks/'+ rowData[0] +'/edit"><span class="glyphicon glyphicon-edit"></span></a>';	
							}
							
				    		$(td).html(innerHtml);
						}
					}
				],
			    "order": [[ 1, "desc" ]],
			    "processing": true,
			    "serverSide": true,
			    "ajax": {
			    	url: urls[0],
			    	method: 'post',
			    	data: {
			    		page: function() {
			    			return $('#ingress_trunks_table').DataTable().page.info().page + 1;
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

			        $(this).find('input.trunk-cb:checkbox').attr('checked', false);
			        toggleGroupButtons();
			    }
			});
		};

		var toggleGroupButtons = function() {
			if ($("div.ingress-trunks-container input.trunk-cb:checkbox:checked").length > 0) {
				$('button.btn_change_all_status').removeClass('disabled');	
			}			
			else {
				$('button.btn_change_all_status').addClass('disabled');
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

	App.EgressTrunkFormHandler = (function($) {
		var urls; 
		var $call_limit_spinner, $cps_limit_spinner, $profit_margin_value_spinner,
			$profit_margin_pc_spinner, $try_timeout_spinner, $pdd_timeout_spinner,
			$ring_timeout_spinner, $decimal_points_spinner, $max_duration_spinner,
			$max_cost_spinner, $top_down_depth_spinner;

		var init = function(toggleStatuses) {
  			$(".select2").select2({
    			width: '75%'
  			});

  			$("#egress_trunk_routing_strategy").select2({
  				width: '75%',
  			}).on('change', function() {
  				var val = $(this).val();
  				$('#top_down_depth_cont').hide();

  				if(val == '1') {
  					$('#top_down_depth_cont').show();
  				}
  			});

  			$("#egress_trunk_profit_margin_type").select2({
  				width: '75%',
  			}).on('change', function() {
  				var val = $(this).val();
  				
  				if(val == '0') {
  					$('label#profit_margin_type_msg').hide();
  					$('#profit_margin_value_cont').show();
  					$('#profit_margin_pc_cont').hide();
  				}
  				else if(val == '1') {
  					$('label#profit_margin_type_msg').hide();
  					$('#profit_margin_value_cont').hide();
  					$('#profit_margin_pc_cont').show();
  				}
  				else {
  					$('label#profit_margin_type_msg').show();
  					$('#profit_margin_value_cont').hide();
  					$('#profit_margin_pc_cont').hide();
  				}
  			});

  			$(document).on('nested:fieldRemoved', function(event){
				event.field.removeClass('fields');
				
				$('.add_nested_fields').removeClass('disabled');
				
				if($('div.fields').filter(":visible").length < 1) {
					$('table#host_headings').hide();
					$('div#add_host_warning').show();
				}
  			});

  			$(document).on('nested:fieldAdded', function(event){
  				if($("span#ip_auth_fields .fields").length >= 12) {
  					$('.add_nested_fields').addClass('disabled');
  				}

				$('table#host_headings').show();
				$('div#add_host_warning').hide();
				$('.tooltips').tooltip({ container: 'body'});
  			});


  			$('.cancel-form').click(function(e) {
  				window.location.href = urls[0];
  				return false;
  			});

  			$top_down_depth_spinner = $('#top_down_depth_spinner').spinner({
				numberFormat: "n",
				step: 1,
				min: 0,
				max: 10,
				value: 0
			});

  			$call_limit_spinner = $('#call_limit_spinner').spinner({
				numberFormat: "n",
				step: 10,
				min: 0,
				max: 10000,
				value: 0
			});

			$cps_limit_spinner = $('#cps_limit_spinner').spinner({
				numberFormat: "n",
				step: 5,
				min: 0,
				max: 500,
				value: 0
			});

			$profit_margin_value_spinner = $('#profit_margin_value_spinner').spinner({
				numberFormat: "n",
				step: 1,
				min: -500,
				max: 500,
				value: 0
			});

			$profit_margin_pc_spinner = $('#profit_margin_pc_spinner').spinner({
				numberFormat: "n",
				step: 0.01,
				min: -1,
				max: 1,
				value: 0
			});

			$try_timeout_spinner = $('#try_timeout_spinner').spinner({
				numberFormat: "n",
				step: 1,
				min: 1,
				max: 60,
				value: 2
			});

			$pdd_timeout_spinner = $('#pdd_timeout_spinner').spinner({
				numberFormat: "n",
				step: 1,
				min: 1,
				max: 60,
				value: 6
			});

			$ring_timeout_spinner = $('#ring_timeout_spinner').spinner({
				numberFormat: "n",
				step: 1,
				min: 1,
				max: 120,
				value: 60
			});

			$decimal_points_spinner = $('#decimal_points_spinner').spinner({
				numberFormat: "n",
				step: 1,
				min: 2,
				max: 8,
				value: 4
			});

			$max_duration_spinner = $('#max_duration_spinner').spinner({
				numberFormat: "n",
				step: 100,
				min: 60,
				max: 7200,
				value: 7200
			});

			$max_cost_spinner = $('#max_cost_spinner').spinner({
				numberFormat: "n",
				step: 0.01,
				min: 0,
				max: 1,
				value: 0
			});

			$("#siptrace_activation_tgl").toggles({ on: toggleStatuses[0], checkbox: $("#sip_trace_tgl_chkbox"), 'event': 'toggle', text: {on: "Yes", off: "No"}});
			$("#media_bypass_activation_tgl").toggles({ on: toggleStatuses[1], checkbox: $("#media_bypass_tgl_chkbox"), 'event': 'toggle', text: {on: "Yes", off: "No"}});
			$("#lrn_block_activation_tgl").toggles({ on: toggleStatuses[2], checkbox: $("#lrn_block_tgl_chkbox"), 'event': 'toggle', text: {on: "Yes", off: "No"}});
			$("#block_wireless_activation_tgl").toggles({ on: toggleStatuses[3], checkbox: $("#block_wireless_tgl_chkbox"), 'event': 'toggle', text: {on: "Yes", off: "No"}});

			$.validator.addMethod("cid", function(value, element) {
				return this.optional(element) || /^[\d\+]+$/.test(value);
			}, "Only digits and '+' sign is allowed");

			$.validator.addMethod("techprefix", function(value, element) {
				return this.optional(element) || /^[\d#]+$/.test(value);
			}, "Only digits and '#' is allowed");

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
					if (validateSpinners() && validateIPAuthentication()) {
						form.submit();
					}
				},
				rules : {
					"egress_trunk[carrier_id]": {
						required: true,
						digits: true
					},
					"egress_trunk[rate_sheet_id]": {
						required: true,
						digits: true
					},
					"egress_trunk[tech_prefix]": {
						techprefix: true
					},
					"egress_trunk[profit_margin_type]": {
						required: true,
						digits: true
					},
					"eggress_trunk[force_cid]": {
						cid: true
					},
					"egress_trunk[name]" : {
						required : true,
						minlength: 3,
						maxlength: 25,
						remote : {
							url : urls[1],
							type : "get",
						}
					}
				},
				messages : {
					"egress_trunk[name]" : {
						remote : "This trunk name already exists with us."
					}
				}
			};

			$editFormValidator = $('#editEgressTrunkForm').validate($.extend(true, {}, validationOptions, {
				rules: {
					"egress_trunk[name]": {remote: {
						data: {id: $('#egress_trunk_id').val()}
					}},
				}
			}));
			
			$newFormValidator = $('#newEgressTrunkForm').validate($.extend(true, {}, validationOptions, {}));

			$('#editEgressTrunkWizard').bootstrapWizard({
				'nextSelector' : '.next',
				'previousSelector' : '.previous',

				onNext : function(tab, navigation, index) {
					if(index == 2) return true;

					return validateEditForm() && validateIPAuthentication();
				},
				onPrevious : function(tab, navigation, index) {
					return validateEditForm() && validateSpinners();
				},
				onTabClick: function(tab, navigation, index) {
					return validateEditForm() && validateSpinners() && validateIPAuthentication();
				}
			});

  			$('#newEgressTrunkWizard').bootstrapWizard({
				'nextSelector' : '.next',
				'previousSelector' : '.previous',
				onNext : function(tab, navigation, index) {
					if(index == 2) return true;

					$('#newFormFinishBtn').addClass('disabled');
					
					if(validateNewForm() && validateSpinners() && validateIPAuthentication()) {
						if (index == 1) {
							$('#newFormFinishBtn').removeClass('disabled');
						}
						
						return true;
					}
					
					return false;
				},
				onPrevious : function(tab, navigation, index) {
					$('#newFormFinishBtn').addClass('disabled');
					return true;
				},
				onTabClick: function(tab, navigation, index) {
					return false;
    			}
			});
		};

		var validateSpinners = function() {
			var isValid = true;
			$.each([$call_limit_spinner, $cps_limit_spinner, $profit_margin_value_spinner,
					$profit_margin_pc_spinner, $try_timeout_spinner, $pdd_timeout_spinner,
					$ring_timeout_spinner, $decimal_points_spinner, $max_duration_spinner,
					$max_cost_spinner, $top_down_depth_spinner], function(i, $el) {

				var errorMsg = '';
				var value = $el.spinner("value");
				var min = $el.spinner("option", "min");
				var max = $el.spinner("option", "max");
				var id = $el.attr('id');
				
				if($el.is(':visible')) {
					if(value == null){
						errorMsg = 'Please input a number.';
						isValid = false;	
					}
					else if($.inArray(i, [0, 1, 4, 5, 6, 7, 8, 10]) >= 0 && /\D/.test(value)) {
						errorMsg = 'Please input a integer value.';
						isValid = false;	
					}
					else if(i == 2 && !(/^\-?[0-9]+$/.test(value))) {
						errorMsg = 'Please input a integer value.';
						isValid = false;	
					}
					else {
						if(value < min || value > max) {
							errorMsg = 'Please select the value that lie between ' +  min + ' to ' + max + '.';
							isValid = false;
						}	
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
		}

		var validateIPAuthentication = function() {
			var error = false;
			var postData = new Array();
			
			if($("span#ip_auth_fields .fields").length < 1) {
				$('.settings-err-msg').html('Please add atleast one host.').show();
				return false;
			}

			$("span#ip_auth_fields .fields").each(function() {
				$('.settings-err-msg').hide();

				$ip_address = $(this).find('.ip_address');
				$subnet = $(this).find('.subnet');
				$port = $(this).find('.port');

				postData.push([$ip_address.val(), $subnet.val(), $port.val()]);
				
				$ip_address.removeClass('settings-error');
				$subnet.removeClass('settings-error');
				$port.removeClass('settings-error');

				if($.trim($ip_address.val()) == '' || !( /^(([1-9]?\d|1\d\d|2[0-5][0-5]|2[0-4]\d)\.){3}([1-9]?\d|1\d\d|2[0-5][0-5]|2[0-4]\d)$/i.test($ip_address.val()))) {
					$ip_address.addClass('settings-error');
					error = true;
				}

				if($.trim($subnet.val()) == '' || !(/^\d+$/.test($subnet.val())) || parseInt($subnet.val()) < 0 || parseInt($subnet.val()) > 32) {
					$subnet.addClass('settings-error');
					error = true;
				}

				if($.trim($port.val()) == '' || !(/^\d+$/.test($port.val())) || parseInt($port.val()) < 0 || parseInt($port.val()) > 65535) {
					$port.addClass('settings-error');
					error = true;
				}
			});

			if(error) {
				$('.settings-err-msg').html('Please fix the error(s) for field(s) marked in red. Hover over fields to check valid values.').show();
			}
			else {
				$.ajax({
			        type: "POST",
			        async: false,
			        url: urls[2],
			        data: {'data': postData, 'id': $('#egress_trunk_id').val()},
			        dataType: 'json',
			        success: function(response) {
			        	if(response.length == 0) {
			        		error = false;
			        	}
			        	else {
			        		$('.settings-err-msg').html('Row(s) '+ response.join(', ') +' already exists with us. The combination of Host, Subnet and Port should be unique.').show();
			        		error = true;	
			        	}
			        },
			        error: function() {
			        	error = true;
			        }
			    });
			}

			return !error;
		};

		var validateNewForm = function() {
			var $valid = $('#newEgressTrunkForm').valid();
					
			if (!$valid) {
				$newFormValidator.focusInvalid();
				return false;
			}
			
			return true;
		};

		var validateEditForm = function() {
			var $valid = $('#editEgressTrunkForm').valid();
					
			if (!$valid) {
				$editFormValidator.focusInvalid();
				return false;
			}
			
			return true;
		};

		var resetSpinnersTo = function(values) {
			$call_limit_spinner.spinner("value", values[0]);
			$cps_limit_spinner.spinner("value", values[1]);
			$profit_margin_value_spinner.spinner("value", values[2]);
			$profit_margin_pc_spinner.spinner("value", values[3]);
			$try_timeout_spinner.spinner("value", values[4]);
			$pdd_timeout_spinner.spinner("value", values[5]);
			$ring_timeout_spinner.spinner("value", values[6]);
			$decimal_points_spinner.spinner("value", values[7]);
			$max_duration_spinner.spinner("value", values[8]);
			$max_cost_spinner.spinner("value", values[9]);
			$top_down_depth_spinner.spinner("value", values[10]);
		};

		var setUrls = function(arr) {
			urls = arr;
		}

		return {
			init: init,
			setUrls: setUrls,
			resetSpinnersTo: resetSpinnersTo
		};
			
	})(jQuery);

	App.EgressTrunkListHandler = (function($) {
		var urls, destroy_trunk, disable_trunk, enable_trunk,
			bulk_operation = false; 

		var init = function(options) {
			$(document).on('click', 'a.close_modal', function() {
				$(this).parents('.modal').modal('hide');					
				bulk_operation = false;
			});

			$("#carrier_select").select2({
  				width: '225px'
  			}).on('change', function() {
				$('#egress_trunks_table').DataTable().columns(2).search($(this).val()).draw();
  			});

  			if(options[0] > 0) {
  				$("#carrier_select").select2('val', options[0]);
  			}

			$("div.checkbox_toggler_container").on('click', '.result_select_all', function() {
				$("div.egress-trunks-container input.trunk-cb:checkbox:not(:checked)").attr('checked', true);	
				toggleGroupButtons();
			});
			
			$("div.checkbox_toggler_container").on('click', '.result_deselect_all', function() {
				$("div.egress-trunks-container input.trunk-cb:checkbox:checked").attr('checked', false);
				toggleGroupButtons();
			});
			
			$("div.checkbox_toggler_container").on('click', '.result_invert_sel', function() {
				$("div.egress-trunks-container input.trunk-cb:checkbox").click();
				toggleGroupButtons();
			});

			$("div.egress-trunks-container").on('click', 'input.trunk-cb:checkbox', function() {
				toggleGroupButtons();
			});

			$('table#egress_trunks_table').on('click', '.trunk_destroy', function() {
				destroy_trunk = $(this).data('trunk-id');

				$('.delete-trunk-confirm-dlg').modal('show');

				return false;
			});

			$('#del_trunk_confirm_ok').click(function () {
				if(bulk_operation) {
					$('form#selected_trunks_form').submit();
				}
				else {
					var link = "a#trunk_" + destroy_trunk + "_destroy_link";
					$(link).click();	
				}
				
				$('.delete-trunk-confirm-dlg').modal('hide');
				bulk_operation = false;
			});

			$('table#egress_trunks_table').on('click', '.trunk_disable', function() {
				disable_trunk = $(this).data('trunk-id');

				$('.disable-trunk-confirm-dlg').modal('show');

				return false;
			});

			$('#disable_trunk_confirm_ok').click(function () {
				if(bulk_operation) {
					$('form#selected_trunks_form').submit();
				}
				else {
					var link = "a#trunk_" + disable_trunk + "_disable_link";
					$(link).click();	
				}
				
				$('.disable-trunk-confirm-dlg').modal('hide');
				bulk_operation = false;
			});

			$('table#egress_trunks_table').on('click', '.trunk_enable', function() {
				enable_trunk = $(this).data('trunk-id');

				$('.enable-trunk-confirm-dlg').modal('show');

				return false;
			});

			$('#enable_trunk_confirm_ok').click(function () {
				if(bulk_operation) {
					$('form#selected_trunks_form').submit();
				}
				else {
					var link = "a#trunk_" + enable_trunk + "_enable_link";
					$(link).click();
				}

				$('.enable-trunk-confirm-dlg').modal('hide');
				bulk_operation = false;
			});

			$('button.btn_change_all_status').click(function() {
				bulk_operation = true;
				$('form#selected_trunks_form').attr('action', $(this).data('url'));
			});

			$('#egress_trunks_table').DataTable({
				resposive: true,
				/*"sDom": '<"top"l>rt<"bottom"ip><"clear">',*/
				"lengthMenu": [ [5, 10, 25, 50, 100, -1], [5, 10, 25, 50, 100, "All"] ],
				"displayLength": 25,
				"columnDefs":[
					{
			    	"targets" : 'no-sort',
			    	"orderable" : false,
			    	},
			    	{
				    	"targets": 0,
				    	"createdCell": function (td, cellData, rowData, row, col) {
							$(td).addClass('text-center').html('<input type="checkbox" name="egress_trunk_ids[]" class="trunk-cb" value="'+ cellData +'">');
						}
					},
					{
						"targets": 5,
						"createdCell": function (td, cellData, rowData, row, col) {
							innerHtml = '';
							if(cellData) {
								innerHtml += ' <a href="#" rel="nofollow" data-trunk-id="'+ rowData[0] +'" title="Deactivate" class="btn btn-warning btn-xs trunk_disable"><span class="glyphicon glyphicon-lock"></a> ';
								innerHtml += ' <a href="/egress_trunks/'+ rowData[0] +'/deactivate" rel="nofollow" data-remote="true" data-method="put" id="trunk_'+ rowData[0] +'_disable_link"></a>';
							}
							else {
								innerHtml += ' <a href="#" rel="nofollow" data-trunk-id="'+ rowData[0] +'" title="Activate" class="btn btn-primary btn-xs trunk_enable"><span class="glyphicon glyphicon-check"></a> ';
								innerHtml += ' <a href="/egress_trunks/'+ rowData[0] +'/activate" rel="nofollow" data-remote="true" data-method="put" id="trunk_'+ rowData[0] +'_enable_link"></a>';
							}
							
							innerHtml += ' <a class="btn btn-default btn-xs" title="Modify" href="/egress_trunks/'+ rowData[0] +'/edit"><span class="glyphicon glyphicon-edit"></span></a>';
							innerHtml += ' <a href="#" rel="nofollow" data-trunk-id="'+ rowData[0] +'" title="Delete" class="btn btn-danger btn-xs trunk_destroy"><span class="glyphicon glyphicon-trash"></span></a> ';
							innerHtml += ' <a href="/egress_trunks/'+ rowData[0] +'" rel="nofollow" data-remote="true" data-method="delete" id="trunk_'+ rowData[0] +'_destroy_link"></a>';
				    		$(td).html(innerHtml);
						}
					}
				],
			    "order": [[ 1, "desc" ]],
			    "processing": true,
			    "serverSide": true,
			    "deferLoading": true,
			    "ajax": {
			    	url: urls[0],
			    	method: 'post',
			    	data: {
			    		page: function() {
			    			return $('#egress_trunks_table').DataTable().page.info().page + 1;
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

			        $(this).find('input.trunk-cb:checkbox').attr('checked', false);
			        toggleGroupButtons();
			    }
			});
		};

		var toggleGroupButtons = function() {
			if ($("div.egress-trunks-container input.trunk-cb:checkbox:checked").length > 0) {
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
});


