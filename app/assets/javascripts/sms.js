//= require bootstrap.min
//= require modernizr.min
//= require toggles.min
//= require retina.min
//= require jquery.cookies
//= require jquery.datatables.min
//= require jquery.gritter.min
//= require select2.min
//= require jquery.validate.min
//= require jquery.tagsinput.min
//= require moment
//= require bootstrap-datetimepicker
//= require custom
//= require_self	

var App = App || {};

$(document).ready(function() {
	var urls, timer, smsId;

	App.SMSLogsAdminHandler = (function($) {
		var init = function() {
			
			$(document).on('click', 'a.close_modal', function() {
				$(this).parents('.modal').modal('hide');
			});

			$("#message_logs").on('click', '.clickable-row', function() {
        		window.document.location = $(this).data("href");
    		});
    		
    		if(smsId) {
				$(".view-smslog-dlg .modal-content").load("/sms_logs/" + smsId);
    			$('.view-smslog-dlg').modal('show');
    		}; 

    		$('.view-smslog-dlg').on('show.bs.modal', function(e) {
    			var url = $(e.relatedTarget).data('url');
    			$(".view-smslog-dlg .modal-content").load(url);
    		});

    		$("#carrier_select").select2({
  				width: '100%'
  			}).on('change', function() {
				$('#message_logs').DataTable().columns(0).search($(this).val()).draw();
  			});

			$("#message_status").select2({
  				width: '100%'
  			}).on('change', function() {
				$('#message_logs').DataTable().columns(4).search($(this).val()).draw();  		
  			});
  			
  			$("#message_direction").select2({
          width: '100%'
        }).on('change', function() {
        $('#message_logs').DataTable().columns(3).search($(this).val()).draw();     
        });

  			$('#from_date').datetimepicker({
  				format: 'YYYY-MM-DD HH:mm:ss'
  			});

  			$('#to_date').datetimepicker({
  				format: 'YYYY-MM-DD HH:mm:ss',
  				useCurrent: true
  			});

  			$("#from_date").on("dp.change", function (e) {
  				var to_date = $('#to_date').val();
  				var from_date = $('#from_date').val();

  				if(e.date == null) {
  					$('#from_date').val($('#to_date').val());
  					from_date = to_date;
  				}
  				else {
  					if(moment(from_date).isAfter(to_date)) {
  						$('#to_date').val($('#from_date').val());
  					}
  					
  					$('#to_date').data("DateTimePicker").minDate(e.date);
  				}

  				$('#message_logs').DataTable().columns(2).search(from_date + '|' + to_date).draw();
	       	});

	       	$("#to_date").on("dp.change", function (e) {
	       		var to_date = $('#to_date').val();
    			var from_date = $('#from_date').val();
    				
  	       		if(e.date == null) {
					$('#to_date').val($('#from_date').val());
					to_date = from_date;
				}
				else {
					if(moment(to_date).isBefore(from_date)) {
						$('#from_date').val($('#to_date').val());
					}

					$('#from_date').data("DateTimePicker").maxDate(e.date);
				}

				$('#message_logs').DataTable().columns(2).search(from_date + '|' + to_date).draw();
	       	});


  			$('#message_logs').DataTable({
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
				    	"targets": 4,
				    	"createdCell": function (td, cellData, rowData, row, col) {
				    		switch(cellData) {
				    			case 'success':
				    				$(td).html('<span class="label label-success">Success</span>');
				    			break;
				    			case 'partial success':
				    				$(td).html('<span class="label label-warning">Partial Success</span>');
				    			break;
				    			case 'failed':
				    				$(td).html('<span class="label label-danger">Failed</span>');
				    			break;
				    		}
						}
					},
					{
						"targets": 8,
						"createdCell": function (td, cellData, rowData, row, col) {
				    		$(td).html(cellData.truncate(25)).attr("title", cellData);
				    	}
					},
					{
						"targets": 9,
						"createdCell": function (td, cellData, rowData, row, col) {
							innerHtml = '';
							innerHtml += ' <button class="btn btn-default btn-xs" title="Details" data-url="/sms_logs/' + cellData[0] + '" data-toggle="modal" data-target=".view-smslog-dlg"><span class="glyphicon glyphicon-eye-open"></span></button>  ';
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
			    			return $('#message_logs').DataTable().page.info().page + 1;
			    		}
			    	}	
			    },
			    "language": {
					"paginate": {
						"previous": "<<",
						"next": ">>"
			        },
			        "processing": "Processing... " + window.ajax_loader
			    }
			});
			
		};

		var setUrls = function(arr) {
			urls = arr;
		};
		
		var setSmsId = function(id) {
			smsId = id;
		};
		
		
		return {
			init: init,
			setUrls: setUrls,
			setSmsId: setSmsId
		};

	})(jQuery);

	App.SMSLogsCarrierHandler = (function($) {
		var init = function() {
			$(document).on('click', 'a.close_modal', function() {
				$(this).parents('.modal').modal('hide');
			});
			
			if(smsId) {
				$(".view-smslog-dlg .modal-content").load("/sms_logs/"+smsId);
    			$('.view-smslog-dlg').modal('show');
    		};
    		
			$('.view-smslog-dlg').on('show.bs.modal', function(e) {
    			var url = $(e.relatedTarget).data('url');
    			$(".view-smslog-dlg .modal-content").load(url);
    		});

			$("#message_logs").on('click', '.clickable-row', function() {
        		window.document.location = $(this).data("href");
    		});

			$("#message_status").select2({
  				width: '100%'
  			}).on('change', function() {
				$('#message_logs').DataTable().columns(3).search($(this).val()).draw();
  			});
  			
  			$("#message_direction").select2({
          width: '100%'
        }).on('change', function() {
        $('#message_logs').DataTable().columns(2).search($(this).val()).draw();     
        });

  			$('#from_date').datetimepicker({
  				format: 'YYYY-MM-DD HH:mm:ss'
  			});

  			$('#to_date').datetimepicker({
  				format: 'YYYY-MM-DD HH:mm:ss',
  				useCurrent: true
  			});

  			$("#from_date").on("dp.change", function (e) {
  				var to_date = $('#to_date').val();
  				var from_date = $('#from_date').val();

  				if(e.date == null) {
  					$('#from_date').val($('#to_date').val());
  					from_date = to_date;
  				}
  				else {
  					if(moment(from_date).isAfter(to_date)) {
  						$('#to_date').val($('#from_date').val());
  					}
  					
  					$('#to_date').data("DateTimePicker").minDate(e.date);
  				}

  				$('#message_logs').DataTable().columns(1).search(from_date + '|' + to_date).draw();
	       	});

	       	$("#to_date").on("dp.change", function (e) {
	       		var to_date = $('#to_date').val();
    			var from_date = $('#from_date').val();
    				
  	       		if(e.date == null) {
					$('#to_date').val($('#from_date').val());
					 to_date = from_date;
				}
				else {
					if(moment(to_date).isBefore(from_date)) {
						$('#from_date').val($('#to_date').val());
					}

					$('#from_date').data("DateTimePicker").maxDate(e.date);
				}

				$('#message_logs').DataTable().columns(1).search(from_date + '|' + to_date).draw();
	       	});


  			$('#message_logs').DataTable({
				resposive: true,
				// "sDom": '<"top"l>rt<"bottom"ip><"clear">',
				"lengthMenu": [ [5, 10, 25, 50, 100, -1], [5, 10, 25, 50, 100, "All"] ],
				"displayLength": 10,
				"columnDefs":[
					{
			    	"targets" : 'no-sort',
			    	"orderable" : false,
			    	},
			    	{
				    	"targets": 3,
				    	"createdCell": function (td, cellData, rowData, row, col) {
				    		switch(cellData) {
				    			case 'success':
				    				$(td).html('<span class="label label-success">Success</span>');
				    			break;
				    			case 'partial success':
				    				$(td).html('<span class="label label-warning">Partial Success</span>');
				    			break;
				    			case 'failed':
				    				$(td).html('<span class="label label-danger">Failed</span>');
				    			break;
				    		}
						}
					},
					{
						"targets": 7,
						"createdCell": function (td, cellData, rowData, row, col) {
				    		$(td).html(cellData.truncate(25)).attr("title", cellData);
				    	}
					},
					{
						"targets": 8,
						"createdCell": function (td, cellData, rowData, row, col) {
							innerHtml = '';
							innerHtml += ' <button class="btn btn-default btn-xs" title="Details" data-url="/sms_logs/' + cellData[0] + '" data-toggle="modal" data-target=".view-smslog-dlg"><span class="glyphicon glyphicon-eye-open"></span></button>  ';
				    		$(td).html(innerHtml);
						}
					}
				],
			    "order": [[ 0, "desc" ]],
			    "processing": true,
			    "serverSide": true,
			    "ajax": {
			    	url: urls[0],
			    	method: 'post',
			    	data: {
			    		page: function() {
			    			return $('#message_logs').DataTable().page.info().page + 1;
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
		
		var setSmsId = function(id) {
			smsId = id;
		};

		return {
			init: init,
			setUrls: setUrls,
			setSmsId: setSmsId
		};

	})(jQuery);

	App.SendSMSHandler = (function($) {
		var urls, isAdmin;

		var init = function(config, admin) {
			isAdmin = admin;
			var validationRules;

			if(isAdmin) {
				$("#message_carrier_id").select2({
	    			width: '100%'
	  			}).on('change', function() {
	  				url = urls[0] + "/" + $(this).val();
	  				App.overlayModal.show();
	  				$.getScript(url, function() {
	  					App.overlayModal.hide();
	  				});
	  			});
			}
			
			$('.select2').select2({
				width: '95%'
			});

			$.validator.addMethod("limit", function(value, element, max) {
				var tags_count = $('#message_recipients_tagsinput span.tag').length;
				return this.optional(element) || tags_count > 1 || tags_count < max;
			}, $.validator.format("Recipients are required with max. limit of {0}."));

			validationRules = {
				"message[from]": {
					required: true,
					limit: 10
				},
				"message[recipients]": {
					required: true,
					limit: config[0]
				},
				"message[text]": { 
					required: true
				}
			};

			if(isAdmin) {
				validationRules = {
					"message[carrier_id]": {
						required: true
					},
					"message[from]": {
						required: true,
						limit: 10
					},
					"message[recipients]": {
						required: true,
						limit: config[0]
					},
					"message[text]": { 
						required: true
					}
				};
			}

			validationOptions = {
				debug : false,
				ignore: [],
				highlight : function(element) {
					$(element).closest('.form-group').removeClass('has-success').addClass('has-error');
				},
				success : function(element) {
					$(element).closest('.form-group').removeClass('has-error');
				},
				submitHandler : function(form) {
					$.get(' /smses/send_sms_credit', {
						carrier: $('#message_carrier_id').val(),
						message: $('#message_text').val(),
						recipients: $('#message_recipients_tagsinput span.tag').length
					}, 
					function(data) {
						if(data == 'true') {
							form.submit();
						}
						else {
							var gritter_opts = {
								title: 'Send SMS',
								sticky: false,
								time: '5000',
								text: 'You do not have enough credit to send this SMS.',
								class_name: 'growl-danger'
							};
							$.gritter.add(gritter_opts);
						}
					});
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
				rules : validationRules,
				messages : {}
			}; 
			
			$newMessageFormValidator = $('#new_message_form').validate(validationOptions);

			$('#message_recipients').tagsInput({
				width:'auto',
				height: '75px',
				defaultText:'',
				minChars : 10,
				maxChars: 20,
				onAddTag: function(tag) {
					var tags_count = $('div#message_recipients_tagsinput span.tag').length;

					if(tags_count > config[0] || !(/^\+\d+$/.test(tag))) {
						$(this).removeTag(tag);
					}
				}
			});

			$('#add_recipient').click(function() {
				var value = $('#number').val();
				var code = $().val();
				if($.trim(value) == '' || !(/^\d+$/.test(value))) {
					$('#number').val('');
					return;
				}

				$('#message_recipients').addTag($('span#country_code').html() + value);
				$('#number').val('');
			});

			$(document).on('keyup keypress', 'form input#number', function(e) {
			  if(e.keyCode == 13) {
			    e.preventDefault();
			    $('#add_recipient').click();
			    return false;
			  }
			});

			$('a.country-code-val').click(function() {
				$('span#country_code').html($(this).html());
			});

			$('#message_text').keyup(function(e) {
				var chars_count = $(this).val().length;
				var message = $(this).val();
				var max_chars = config[1];
				var single_sms_length = config[2];
				var message_count, chars_left;

				if(chars_count == 0) {
					$('#msg_count').html(1);
					$('#chars_left').html(single_sms_length);
					return;
				}

				if(chars_count >= max_chars) {
					$(this).val(message.substring(0, max_chars - 1));
					$('#chars_left').html('Max. Limit Reached');
					return;
				}

				message_count = Math.floor(chars_count/single_sms_length);
				chars_left = single_sms_length + message_count*single_sms_length - chars_count;

				if(chars_count%single_sms_length == 0) {
					$('#msg_count').html(message_count);
					$('#chars_left').html('0');
				}
				else {
					$('#msg_count').html(message_count + 1);
					$('#chars_left').html(chars_left);
				}
				
			});
		};

		var initDidsSelect = function() {
			$('#message_from').select2({width: '75%'})
		};

		var setUrls = function(arr) {
			urls = arr;
		};

		return {
			init: init,
			setUrls: setUrls,
			initDidsSelect: initDidsSelect
		};
	})(jQuery);

	App.SMSAPIHandler = (function($) {
		var urls;

		var init = function() {
			$('a#refresh_token').click(function() {
				console.log('clicked');
				$.get(urls[0], {}, function(data) {
					$('span.api-token').html(data.token);
				}, 'json');
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