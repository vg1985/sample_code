//= require bootstrap.min
//= require modernizr.min
//= require toggles.min
//= require retina.min
//= require jquery.cookies
//= require jquery.gritter.min
//= require select2.min
//= require jquery.validate.min
//= require jquery.detectcard
//= require jquery.datatables.min
//= require moment
//= require bootstrap-datetimepicker
//= require custom
//= require_self

var App = App || {};

$(document).ready(function() {

	App.CommonHandler = (function($) {
		var initCardDetector = function(ccnumberSelector, dimmerSelector, valueSelector) {
			$(ccnumberSelector).detectCard().on("cardChange", function(e, card) {
				if(card != undefined) {
					switch(card.type) {
						case 'visa':
							$(dimmerSelector).css('background-position', '0 -23px');  
                			$(valueSelector).val('visa');
						break;
						case 'mastercard':
							$(dimmerSelector).css('background-position', '0 -46px');  
	                		$(valueSelector).val('master');
						break;
						case 'american-express':
							$(dimmerSelector).css('background-position', '0 -69px');  
							$(valueSelector).val('american_express');
						break;
						case 'discover':
							$(dimmerSelector).css('background-position', '0 -92px');  
							$(valueSelector).val('discover');
						break;
						default:
							$(dimmerSelector).css('background-position', '0 0');  
	                		$(valueSelector).val('');

					}
				}
  			});
		};

		var validatePayment = function(form_id) {
  			validationOptions = {
				debug : false,
				highlight : function(element) {
					$(element).closest('.form-group').removeClass('has-success').addClass('has-error');
				},
				success : function(element) {
					$(element).closest('.form-group').removeClass('has-error');
				},
				submitHandler : function(form) {
					form.submit();
				},
				errorPlacement: function(error, element) {
					if (element.attr("id") == "payment_amount") {
						$("#amount_error").html(error);
				    } 
				     else {
				        // the default error placement for the rest
				        error.insertAfter(element);
				    }
				},
				rules : {
					"payment[amount]" : {
						required: true,
						number: true,
						min: 1
					},
					"payment[description]": {
						minlength: 3,
						maxlength: 250
					},
					"payment[transaction_details]": {
						minlength: 3,
						maxlength: 250
					}
				},
				messages : {}
			}; 
			
			return $(form_id).validate(validationOptions);
		};

		return {
			initCardDetector: initCardDetector,
			validatePayment: validatePayment		
		}
	})(jQuery);

	App.AddChargeHandler = (function($) {
		var init = function() {
			$(".select2").select2({
    			width: '75%'
  			});

  			$('#for_date').datetimepicker({
  				format: 'YYYY-MM-DD HH:mm',
  				useCurrent: true
  			});

  			validationOptions = {
				debug : false,
				highlight : function(element) {
					$(element).closest('.form-group').removeClass('has-success').addClass('has-error');
				},
				success : function(element) {
					$(element).closest('.form-group').removeClass('has-error');
				},
				submitHandler : function(form) {
					form.submit();
				},
				errorPlacement: function(error, element) {
					if (element.attr("id") == "payment_amount") {
						$("#amount_error").html(error);
				    } 
				     else {
				        // the default error placement for the rest
				        error.insertAfter(element);
				    }
				},
				rules : {
					"payment[amount]" : {
						required: true,
						number: true,
						min: 1
					},
					"payment[carrier_id]": {
						required: true,
						digits: true,
						min: 1
					},
					"payment[charge_type]": { 
						required: true,
						minlength: 3
					},
				},
				messages : {}
			}; 
			
			$newChargesFormValidator = $('#new_charge_form').validate(validationOptions);
		}

		return {
			init: init
		}
	})(jQuery);

	App.AddPaymentHandler = (function($) {
		var urls; 
		var isAdmin;

		var init = function(admin) {
			isAdmin = admin;
			$("#payment_carrier_id").select2({
    			width: '75%'
  			}).on('change', function() {
  				url = urls[0] + "/" + $(this).val();
  				$.getScript(url);
  			});
  			
  			$(".select2").select2({
    			width: '75%'
  			});

  			$('#for_date').datetimepicker({
  				format: 'YYYY-MM-DD HH:mm',
  				useCurrent: true
  			});

  			initPaymentType();

  			validationOptions = {
				debug : false,
				highlight : function(element) {
					$(element).closest('.form-group').removeClass('has-success').addClass('has-error');
				},
				success : function(element) {
					$(element).closest('.form-group').removeClass('has-error');
				},
				submitHandler : function(form) {
					form.submit();
				},
				errorPlacement: function(error, element) {
					if (element.attr("id") == "payment_amount") {
						$("#amount_error").html(error);
				    } 
				     else {
				        // the default error placement for the rest
				        error.insertAfter(element);
				    }
				},
				rules : {
					"payment[amount]" : {
						required: true,
						number: true,
						min: 1
					},
					"payment[carrier_id]": {
						required: true,
						digits: true,
						min: 1
					},
					"payment[payment_type]" : {
						required : true
					},
					"credit_card[storage_id]": {
						required: true
					},
					"payment[custom_type]": { 
						required: true,
						minlength: 3,
						maxlength: 250
					},
					"credit_card[number]": {
						required: true,
						creditcard: true
					},
					"credit_card[verification_value]": {
						required: true,
						digits: true,
						minlength: 3,
						maxlength: 4
					},
					"credit_card[first_name]": {
						required: true,
						minlength: 2,
						maxlength: 250
					},
					"credit_card[last_name]": {
						required: true,
						minlength: 2,
						maxlength: 250
					},
					"payment[transaction_details]": {
						required: function() {
							return !isAdmin;
						},
						minlength: 3
					}
				},
				messages : {}
			}; 
			
			$newPaymentFormValidator = $('#new_payment_form').validate(validationOptions);

  			toggleButtons();
		};

		var initPaymentType = function() {
			$("#payment_type").select2({
    			width: '75%'
  			}).on('change', function() {
  				toggleButtons();
  			});

  			$("#credit_card_storage_id").select2({
    			width: '75%'
  			}).on('change', function() {
  				if($(this).val() == '-1') {
  					$('.credit-card-field').show();
  				}
  				else {
  					$('.credit-card-field').hide();
  				}
  			});

  			App.CommonHandler.initCardDetector("input#credit_card_number", '#cctypedimmer', '#credit_card_brand');
		};

		var toggleButtons = function() {
			var type = $("select#payment_type").val();
			$('#custom_type, #cc_list, .credit-card-field, #express-checkout-save').hide();
			$(".make-payment-btn").show();
			
			if(!isAdmin) {
				$('#transaction_details').hide();
			}

			switch(type) {
				case 'paypal': 
    				$("#express-checkout-save").show();
    				$(".make-payment-btn").hide();
				break;
				case 'credit_card':
					$('#cc_list').show();
					$("#credit_card_storage_id").trigger('change');
				break;
				case 'custom':
					$('#custom_type').show();
				break;
				default:
					$('#transaction_details').show();
				break;
			}
		};

		var setUrls = function(arr) {
			urls = arr;
		}

		return {
			init: init,
			setUrls: setUrls,
			initPaymentType: initPaymentType
		};
			
	})(jQuery);

	App.CreditCardsHandler = (function($) {
		var destroy_cc;

		var init = function() {
			Dropzone.autoDiscover = false;
			
			$('table.credit_cards').dataTable({
				resposive: true,
				"lengthMenu": [ [5, 10, 25, 50, 100, -1], [5, 10, 25, 50, 100, "All"] ],
				"columnDefs":[{
					"targets" : 'no-sort',
					"orderable" : false
				}],
				"order": [[ 4, "desc" ]]
			});

			$(document).on('click', 'a.close_modal', function() {
				$(this).parents('.modal').modal('hide');					
			});

			$('.download-supported-docs-dlg').on('show.bs.modal', function(e) {
				var url = $(e.relatedTarget).data('url');
				$(".download-supported-docs-dlg .modal-content").load(url);
			});

			$('table.credit_cards').on('click', '.cc_destroy', function() {
				destroy_cc = $(this).data('cc-id');

				$('.delete-cc-confirm-dlg').modal('show');

				return false;
			});

			$('#del_cc_confirm_ok').click(function () {
				var link = "a#cc_" + destroy_cc + "_destroy_link";
				$(link).click();
				$('.delete-cc-confirm-dlg').modal('hide');
			});
		};

		return {
			init: init
		}
	})(jQuery);

	App.AdminCreditCardsHandler = (function($) {
		var destroy_cc, urls;

		var init = function() {
			Dropzone.autoDiscover = false;

			$("#cc_status").select2({
  				width: '160px'
  			}).on('change', function() {
				$('table.credit_cards').DataTable().columns(6).search($(this).val()).draw();  				
  			});

  			$("#carrier_select").select2({
  				width: '225px'
  			}).on('change', function() {
				$('table.credit_cards').DataTable().columns(0).search($(this).val()).draw();  				
  			});
			
			$('table.credit_cards').dataTable({
				resposive: true,
				//"sDom": '<"top"l>rt<"bottom"ip><"clear">',
				"lengthMenu": [ [5, 10, 25, 50, 100, -1], [5, 10, 25, 50, 100, "All"] ],
				"displayLength": 25,
				"columnDefs":[
					{
			    	"targets" : 'no-sort',
			    	"orderable" : false,
			    	},
			    	{
				    	"targets": 6,
				    	"createdCell": function (td, cellData, rowData, row, col) {
				    		if(cellData) {
				    			$(td).html('<span title="Verified" class="glyphicon glyphicon-ok text-success"></span>');
				    		}
				    		else {
				    			$(td).html('<span title="Pending Verification" class="glyphicon glyphicon-pause"></span>');
				    		}

				    		$(td).addClass("text-center");
						}
					},
					{
				    	"targets": 7,
				    	"createdCell": function (td, cellData, rowData, row, col) {
				    		if(cellData) {
				    			$(td).html('<span title="Enabled" class="glyphicon glyphicon-ok text-success"></span>');
				    		}
				    		else {
				    			$(td).html('<span title="Disabled" class="glyphicon glyphicon-remove text-warning"></span>');
				    		}

				    		$(td).addClass("text-center");
						}
					},
					{
						"targets": 8,
						"createdCell": function (td, cellData, rowData, row, col) {
							innerHtml = '';
							
							innerHtml += ' <a href="#" title="Supported Documents" class="btn btn-default btn-xs" data-target=".download-supported-docs-dlg" data-toggle="modal" data-url="/credit_cards/'+ cellData[0] +'/check_authorization">'+ cellData[1][1] +'</a>';
							
							if(cellData[2]){
								innerHtml += ' <a href="/credit_cards/'+ cellData[0] + '/activate" data-method="put" rel="nofollow" title="Verify" class="btn btn-primary btn-xs"><span class="glyphicon glyphicon-check"></span></a> ';
							}

							if(cellData[3]) {
								innerHtml += ' <a href="/credit_cards/'+ cellData[0] + '/deactivate" data-method="put" rel="nofollow" title="Unverify" class="btn btn-warning btn-xs"><span class="glyphicon glyphicon-pause"></span></a> ';
							}

							if(cellData[4]) {
								innerHtml += ' <a href="#" rel="nofollow" data-cc-id="'+ cellData[0] +'" title="Delete" class="btn btn-danger btn-xs cc_destroy"><span class="glyphicon glyphicon-trash"></span></a> ';	
								innerHtml += ' <a href="/credit_cards/'+ cellData[0] +'" rel="nofollow" data-method="delete" id="cc_'+ cellData[0] +'_destroy_link"></a> ';	
							}
							
				    		$(td).html(innerHtml);
						}
					}
				],
			    "order": [[ 5, "desc" ]],
			    "processing": true,
			    "serverSide": true,
			    "ajax": {
			    	url: urls[0],
			    	method: 'post',
			    	data: {
			    		page: function() {
			    			return $('table.credit_cards').DataTable().page.info().page + 1;
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
			    
			});

			$(document).on('click', 'a.close_modal', function() {
				$(this).parents('.modal').modal('hide');					
			});

			$('.download-supported-docs-dlg').on('show.bs.modal', function(e) {
				var url = $(e.relatedTarget).data('url');
				$(".download-supported-docs-dlg .modal-content").load(url);
			});

			$('table.credit_cards').on('click', '.cc_destroy', function() {
				destroy_cc = $(this).data('cc-id');

				$('.delete-cc-confirm-dlg').modal('show');

				return false;
			});

			$('#del_cc_confirm_ok').click(function () {
				var link = "a#cc_" + destroy_cc + "_destroy_link";
				$(link).click();
				$('.delete-cc-confirm-dlg').modal('show');
			});
		};

		var setUrls = function(arr) {
			urls = arr;
		};

		return {
			init: init,
			setUrls: setUrls
		}
	})(jQuery);

	App.NewCreditCardHandler = (function($) {
		var urls;

		var init = function(urls) {
			this.urls = urls;

			$('.city_state_select').select2({
				width: '75%'
			}).on('change', function() {
				$('#other_city_state').hide();
				if('OTHER' == $(this).val()) {
					$('#other_city_state').show();
				}
			}).trigger('change');

			$.validator.addMethod("alphaOnly", function(value, element) {
				return this.optional(element) || App.alphaNoSpaceRegex.test(value);
			}, "Nickname can only contain letters and numbers.");

  			validationOptions = {
				debug : false,
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
					"credit_card[nickname]" : {
						required: true,
						alphaOnly: true,
						minlength: 2,
						maxlength: 20,
						remote : {
							url : "/credit_cards/check_nickname",
							type : "get"
						}
					},
					"credit_card[number]": {
						required: true,
						creditcard: true
					},
					"credit_card[verification_value]": {
						required: true,
						digits: true,
						minlength: 3,
						maxlength: 4
					},
					"credit_card[first_name]": {
						required: true,
						minlength: 2,
						maxlength: 250
					},
					"credit_card[last_name]": {
						required: true,
						minlength: 2,
						maxlength: 250
					},
					"credit_card[city_state]": {
						required: true,
					},
					"credit_card[other_city_state]": {
						required: true,
						minlength: 2
					},
					"credit_card[zip_code]": {
						required: true,
						minlength: 3
					}

				},
				messages : {
					"credit_card[nickname]": {
						remote: "Credit Card with this nickname already exists."
					}
				}
			}; 
			
			$newCCFormValidator = $('#new_creditcard_form').validate(validationOptions);

			//$("div#file1").dropzone({ url: "/credit_cards" });
			Dropzone.autoDiscover = false;
			var authFilesDropZone = new Dropzone("div#auth_files",{
			//Dropzone.options.auth_files({
				url: urls[0],
				headers: {"X-CSRF-Token" : $('meta[name="csrf-token"]').attr('content')},
				maxFilesize: 5,
				filesizeBase: 1024,
				addRemoveLinks: true,
				uploadMultiple: false,
				maxFiles: 3,
				acceptedFiles: 'image/*,application/pdf',
				dictDefaultMessage: "<h4>Drop Files here</h4> or click here to upload.",
				dictMaxFilesExceeded: "Maximum 3 files can be uploaded.",
				init: function() {
					this.on("success", function(file, response) { 
						if (response.status == 'success') {
							file.id = response.id;	
						}
					});

					this.on('removedfile', function(file) {
						if(file.id != undefined) {
							$.get(urls[1], {id: file.id});	
						}
					});
				},
				forceFallback: false
			});
			
			$(".add-cc-btn").on('click', function() {
				if($('.fallback').length < 1) {
					var files = new Array();
					$.each(authFilesDropZone.getAcceptedFiles(), function() {
						files.push(this.id);
					});

					$("#uploaded_docs").val(files.join(','));
				}
				
				$('#new_creditcard_form').submit();
			})

			App.CommonHandler.initCardDetector("input#cc_cloud_number", '#cctypedimmer', '#cc_cloud_brand');
		};

		return {
			init: init
		};
			
	})(jQuery);

	App.CarrierPaymentHistoryHandler = (function($) {
		var urls;

		var init = function() {
			$(document).on('click', 'a.close_modal', function() {
				$(this).parents('.modal').modal('hide');					
			});

			$("#payment_status").select2({
  				width: '140px'
  			}).on('change', function() {
				$('#carrier_payments').DataTable().columns(3).search($(this).val()).draw();  		
  			});

  			$("#payment_type").select2({
  				width: '150px'
  			}).on('change', function() {
				$('#carrier_payments').DataTable().columns(0).search($(this).val()).draw(); 
  			});

  			$('.view-payment-dlg').on('show.bs.modal', function(e) {
				var url = $(e.relatedTarget).data('url');
				$(".view-payment-dlg .modal-content").load(url);
			});

			$('.edit-payment-dlg').on('show.bs.modal', function(e) {
				var url = $(e.relatedTarget).data('url');
				$(".edit-payment-dlg .modal-content").load(url);
			});

			//App.CommonHandler.validatePayment("#edit_payment_form");

  			$('#carrier_payments').DataTable({
				resposive: true,
				"sDom": '<"top"l>rt<"bottom"ip><"clear">',
				"lengthMenu": [ [5, 10, 25, 50, 100, -1], [5, 10, 25, 50, 100, "All"] ],
				"columnDefs":[
					{
			    	"targets" : 'no-sort',
			    	"orderable" : false,
			    	},
			    	{
				    	"targets": 3,
				    	"createdCell": function (td, cellData, rowData, row, col) {
				    		switch(cellData) {
				    			case 'Pending':
				    				$(td).html('<span class="label label-default">Pending</span>');
				    			break;
				    			case 'Declined':
				    				$(td).html('<span class="label label-danger">Declined</span>');
				    			break;
				    			case 'Deleted':
				    				$(td).html('<span class="label label-danger">Deleted</span>');
				    			break;
				    			default:
				    				$(td).html('<span class="label label-success">Accepted</span>');
				    		}
						}
					},
					{
						"targets": [4],
						"createdCell": function (td, cellData, rowData, row, col) {
				    		$(td).html(cellData.truncate(25)).attr("title", cellData);
				    	}
					},
					{
						"targets": 5,
						"createdCell": function (td, cellData, rowData, row, col) {
							innerHtml = '';
							innerHtml += ' <button class="btn btn-default btn-xs" title="Details" data-url="/payments/' + cellData[0] + '" data-toggle="modal" data-target=".view-payment-dlg"><span class="glyphicon glyphicon-eye-open"></span></button> ';
							innerHtml += ' <button class="btn btn-default btn-xs" data-url="/payments/' + cellData[0] + '/edit" title="Edit" data-toggle="modal" data-target=".edit-payment-dlg"><span class="glyphicon glyphicon-edit"></span></button> ';	
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
			    			return $('#carrier_payments').DataTable().page.info().page + 1;
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

	App.AdminPaymentHistoryHandler = (function($) {
		var urls;

		var init = function() {
			$(document).on('click', 'a.close_modal', function() {
				$(this).parents('.modal').modal('hide');					
			});

  			$("#payment_status").select2({
  				width: '140px'
  			}).on('change', function() {
				$('#admin_payments').DataTable().columns(4).search($(this).val()).draw();  				
  			});

  			$("#payment_type").select2({
  				width: '150px'
  			}).on('change', function() {
				$('#admin_payments').DataTable().columns(1).search($(this).val()).draw();  				
  			});

  			$("#carrier_select").select2({
  				width: '225px'
  			}).on('change', function() {
				$('#admin_payments').DataTable().columns(0).search($(this).val()).draw();  				
  			});

  			$('.cancel-payment-confirm-dlg').on('show.bs.modal', function(e) {
				var url = $(e.relatedTarget).data('url');
				$(this).find('form').attr('action', url);
			});

			$('.view-payment-dlg').on('show.bs.modal', function(e) {
				var url = $(e.relatedTarget).data('url');
				$(".view-payment-dlg .modal-content").load(url);
			});

			$('.edit-payment-dlg').on('show.bs.modal', function(e) {
				var url = $(e.relatedTarget).data('url');
				$(".edit-payment-dlg .modal-content").load(url);
			});

  			$('#admin_payments').DataTable({
				resposive: true,
				"sDom": '<"top"l>rt<"bottom"ip><"clear">',
				"lengthMenu": [ [5, 10, 25, 50, 100, -1], [5, 10, 25, 50, 100, "All"] ],
				"displayLength": 25,
				"columnDefs":[{
			    	"targets" : 'no-sort',
			    	"orderable" : false,
			    	},
			    	{
				    	"targets": 4,
				    	"createdCell": function (td, cellData, rowData, row, col) {
				    		switch(cellData) {
				    			case 'Pending':
				    				$(td).html('<span class="label label-default">Pending</span>');
				    			break;
				    			case 'Accepted':
				    				$(td).html('<span class="label label-success">Accepted</span>');
				    			break;
				    			case 'Declined':
				    				$(td).html('<span class="label label-danger">Declined</span>');
				    			break;
				    			case 'Deleted':
				    				$(td).html('<span class="label label-danger">Deleted</span>');
				    			break;
				    			default:
				    			$(td).html('<span class="label label-success">Accepted</span>');
				    		}
						}
					},
					/*{
						"targets": [5, 6],
						"createdCell": function (td, cellData, rowData, row, col) {
				    		$(td).html(cellData.truncate(25)).attr("title", cellData);
						}
			    	},*/
			    	{
						"targets": 5,
						"createdCell": function (td, cellData, rowData, row, col) {
							innerHtml = '';

							if(cellData[2]) {
								innerHtml += '<a href="/payments/'+ cellData[0] +'/accept" class="btn btn-success btn-xs" title="Accept" data-method="put"><span class="glyphicon glyphicon-ok"></span></a>';
							}
							else {
								innerHtml += '<a href="#" class="btn btn-success btn-xs disabled" title="Accept"><span class="glyphicon glyphicon-ok"></span></a>';	
							}

							if(cellData[1]) {
								innerHtml += ' <button class="btn btn-warning btn-xs" data-url="/payments/' + cellData[0] + '/set_delete" title="Delete" data-toggle="modal" data-target=".cancel-payment-confirm-dlg"><span class="glyphicon glyphicon-remove-circle"></span></button> ';
							}
							else {
								innerHtml += ' <button class="btn btn-warning btn-xs disabled" title="Delete"><span class="glyphicon glyphicon-remove-circle"></span></button>';	
							}

							innerHtml += ' <button class="btn btn-default btn-xs" title="Details" data-url="/payments/' + cellData[0] + '" data-toggle="modal" data-target=".view-payment-dlg"><span class="glyphicon glyphicon-eye-open"></span></button> ';

							innerHtml += ' <button class="btn btn-default btn-xs" data-url="/payments/' + cellData[0] + '/edit" title="Edit" data-toggle="modal" data-target=".edit-payment-dlg"><span class="glyphicon glyphicon-edit"></span></button> ';	
							/*if(cellData[3]) {
								innerHtml += ' <button class="btn btn-default btn-xs" title="Edit"><span class="glyphicon glyphicon-edit"></span></button> ';
							}
							else {
								innerHtml += ' <button class="btn btn-default btn-xs disabled" data-url="/payments/' + cellData[0] + '" title="Edit" data-toggle="modal" data-target=".view-payment-dlg"><span class="glyphicon glyphicon-edit"></span></button> ';	
							}*/

				    		$(td).html(innerHtml);
						}
			    	}
			    ],
			    "order": [[ 2, "desc" ]],
			    "processing": true,
			    "serverSide": true,
			    "ajax": {
			    	url: urls[0],
			    	method: 'post',
			    	data: {
			    		page: function() {
			    			return $('#admin_payments').DataTable().page.info().page + 1;
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

	App.CarrierChargeHistoryHandler = (function($) {
		var urls;

		var init = function() {
			$(document).on('click', 'a.close_modal', function() {
				$(this).parents('.modal').modal('hide');					
			});

			$("#charge_status").select2({
  				width: '140px'
  			}).on('change', function() {
				$('#carrier_charges').DataTable().columns(3).search($(this).val()).draw();  		
  			});

  			$('.view-charge-dlg').on('show.bs.modal', function(e) {
				var url = $(e.relatedTarget).data('url');
				$(".view-charge-dlg .modal-content").load(url);
			});

			$('.edit-charge-dlg').on('show.bs.modal', function(e) {
				var url = $(e.relatedTarget).data('url');
				$(".edit-charge-dlg .modal-content").load(url);
			});

  			$('#carrier_charges').DataTable({
				resposive: true,
				"sDom": '<"top"l>rt<"bottom"ip><"clear">',
				"lengthMenu": [ [5, 10, 25, 50, 100, -1], [5, 10, 25, 50, 100, "All"] ],
				"columnDefs":[
					{
			    	"targets" : 'no-sort',
			    	"orderable" : false,
			    	},
			    	{
				    	"targets": 3,
				    	"createdCell": function (td, cellData, rowData, row, col) {
				    		switch(cellData) {
				    			case 'Pending':
				    				$(td).html('<span class="label label-default">Pending</span>');
				    			break;
				    			case 'Declined':
				    				$(td).html('<span class="label label-danger">Declined</span>');
				    			break;
				    			case 'Deleted':
				    				$(td).html('<span class="label label-danger">Deleted</span>');
				    			break;
				    			default:
				    				$(td).html('<span class="label label-success">Accepted</span>');
				    		}
						}
					},
					{
						"targets": [4],
						"createdCell": function (td, cellData, rowData, row, col) {
				    		$(td).html(cellData.truncate(25)).attr("title", cellData);
				    	}
					},
					{
						"targets": 5,
						"createdCell": function (td, cellData, rowData, row, col) {
							innerHtml = '';
							innerHtml += ' <button class="btn btn-default btn-xs" title="Details" data-url="/payments/' + cellData[0] + '" data-toggle="modal" data-target=".view-charge-dlg"><span class="glyphicon glyphicon-eye-open"></span></button> ';
							innerHtml += ' <button class="btn btn-default btn-xs" data-url="/payments/' + cellData[0] + '/edit" title="Edit" data-toggle="modal" data-target=".edit-charge-dlg"><span class="glyphicon glyphicon-edit"></span></button> ';	
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
			    			return $('#carrier_charges').DataTable().page.info().page + 1;
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

	App.AdminChargeHistoryHandler = (function($) {
		var urls;

		var init = function() {
			$(document).on('click', 'a.close_modal', function() {
				$(this).parents('.modal').modal('hide');					
			});

  			$("#charge_status").select2({
  				width: '140px'
  			}).on('change', function() {
				$('#admin_charges').DataTable().columns(4).search($(this).val()).draw();  				
  			});
  			
  			$("#carrier_select").select2({
  				width: '225px'
  			}).on('change', function() {
				$('#admin_charges').DataTable().columns(0).search($(this).val()).draw();  				
  			});

  			$('.cancel-charge-confirm-dlg').on('show.bs.modal', function(e) {
				var url = $(e.relatedTarget).data('url');
				$(this).find('form').attr('action', url);
			});

			$('.view-charge-dlg').on('show.bs.modal', function(e) {
				var url = $(e.relatedTarget).data('url');
				$(".view-charge-dlg .modal-content").load(url);
			});

			$('.edit-charge-dlg').on('show.bs.modal', function(e) {
				var url = $(e.relatedTarget).data('url');
				$(".edit-charge-dlg .modal-content").load(url);
			});

  			$('#admin_charges').DataTable({
				resposive: true,
				"sDom": '<"top"l>rt<"bottom"ip><"clear">',
				"lengthMenu": [ [5, 10, 25, 50, 100, -1], [5, 10, 25, 50, 100, "All"] ],
				"displayLength": 25,
				"columnDefs":[{
			    	"targets" : 'no-sort',
			    	"orderable" : false,
			    	},
			    	{
				    	"targets": 4,
				    	"createdCell": function (td, cellData, rowData, row, col) {
				    		switch(cellData) {
				    			case 'Pending':
				    				$(td).html('<span class="label label-default">Pending</span>');
				    			break;
				    			case 'Accepted':
				    				$(td).html('<span class="label label-success">Accepted</span>');
				    			break;
				    			case 'Declined':
				    				$(td).html('<span class="label label-danger">Declined</span>');
				    			break;
				    			case 'Deleted':
				    				$(td).html('<span class="label label-danger">Deleted</span>');
				    			break;
				    			default:
				    			$(td).html('<span class="label label-success">Accepted</span>');
				    		}
						}
					},
					{
						"targets": 5,
						"createdCell": function (td, cellData, rowData, row, col) {
				    		$(td).html(cellData.truncate(25)).attr("title", cellData);
						}
			    	},
			    	{
						"targets": 6,
						"createdCell": function (td, cellData, rowData, row, col) {
							innerHtml = '';

							if(cellData[2]) {
								innerHtml += '<a href="/payments/'+ cellData[0] +'/accept" class="btn btn-success btn-xs" title="Accept" data-method="put"><span class="glyphicon glyphicon-ok"></span></a>';
							}
							else {
								innerHtml += '<a href="#" class="btn btn-success btn-xs disabled" title="Accept"><span class="glyphicon glyphicon-ok"></span></a>';	
							}

							if(cellData[1]) {
								innerHtml += ' <button class="btn btn-warning btn-xs" data-url="/payments/' + cellData[0] + '/set_delete" title="Delete" data-toggle="modal" data-target=".cancel-charge-confirm-dlg"><span class="glyphicon glyphicon-remove-circle"></span></button> ';
							}
							else {
								innerHtml += ' <button class="btn btn-warning btn-xs disabled" title="Delete"><span class="glyphicon glyphicon-remove-circle"></span></button>';	
							}

							innerHtml += ' <button class="btn btn-default btn-xs" title="Details" data-url="/payments/' + cellData[0] + '" data-toggle="modal" data-target=".view-charge-dlg"><span class="glyphicon glyphicon-eye-open"></span></button> ';

							innerHtml += ' <button class="btn btn-default btn-xs" data-url="/payments/' + cellData[0] + '/edit" title="Edit" data-toggle="modal" data-target=".edit-charge-dlg"><span class="glyphicon glyphicon-edit"></span></button> ';	
							/*if(cellData[3]) {
								innerHtml += ' <button class="btn btn-default btn-xs" title="Edit"><span class="glyphicon glyphicon-edit"></span></button> ';
							}
							else {
								innerHtml += ' <button class="btn btn-default btn-xs disabled" data-url="/payments/' + cellData[0] + '" title="Edit" data-toggle="modal" data-target=".view-payment-dlg"><span class="glyphicon glyphicon-edit"></span></button> ';	
							}*/

				    		$(td).html(innerHtml);
						}
			    	}
			    ],
			    "order": [[ 2, "desc" ]],
			    "processing": true,
			    "serverSide": true,
			    "ajax": {
			    	url: urls[0],
			    	method: 'post',
			    	data: {
			    		page: function() {
			    			return $('#admin_charges').DataTable().page.info().page + 1;
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


