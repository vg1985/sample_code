//= require bootstrap.min
//= require modernizr.min
//= require toggles.min
//= require retina.min
//= require jquery.cookies
//= require jquery.datatables.min
//= require select2.min
//= require custom
//= require_self

var App = App || {};

jQuery(document).ready(function() {
	var timeout, urls;
	App.purchaseConfirmation = (function($) {
		var init = function(u, t) {
			/*$('#editable_order_email').editable({
				toggle: 'mouseenter',
				validate: function(value) {
					if($.trim(value) === '')
						return 'This field is required';

					if(!(/^[a-zA-Z0-9.!#$%&'*+\/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$/.test($.trim(value))))
						return "This is an invalid email ID";
				},
				success: function(response, newValue) {
					$('#order_email').val(newValue);
				}
			});*/
			timeout = t;
			urls = u;
			
			startTimer();

			$("#submit_order").click(function() {
				$('.form-group').removeClass('has-error');
				$('#order_email_error').html('');

				if(!orderEmailValid()) {
					return false;
				}
				
				$('form#order_now').submit();
			});
			
			
		};

		var orderEmailValid = function() {
			var el = $('#order_email');
			var value = el.val();
			var error = '';

			if($.trim(value) === '') {
				error = "This field is required"; 					
			}
			else {
				if(!(/^[a-zA-Z0-9.!#$%&'*+\/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$/.test($.trim(value)))) {
					error = "This is an invalid email ID";
				}
			}

			if(error !== '') {
				el.parents('.form-group').addClass('has-error');
				$('#order_email_error').html(error);
				return false;
			}

			return true;
		};
		
		var startTimer = function() {
			var startTime = new Date();
			startTime = startTime.getMinutes() * 60 + startTime.getSeconds() + timeout //timeout in seconds;

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
        			$('#purchase_time_left').addClass('text-danger').html('Oops! Time is out. You will be redirected to purchase page again.');
        			$('#submit_order').addClass('disabled');
        			window.location.href = urls[0] + '?timeout=1';
        			return;
    			}

			    $('#purchase_time_left').html(result);

			}, 500);
		};
		
		var leftPad = function (aNumber) { 
			return (aNumber < 10) ? "0" + aNumber : aNumber;
		};

		return {
			init: init
		};

	})(jQuery);

	App.AdminOrdersHandler = (function($) {
		var urls, timer;

		var init = function() {
			$(document).on('click', 'a.close_modal', function() {
				$(this).parents('.modal').modal('hide');					
			});

			$("#orders").on('click', '.clickable-row', function() {
        		window.document.location = $(this).data("href");
    		});

    		$("#carrier_select").select2({
  				width: '225px'
  			}).on('change', function() {
				$('#orders').DataTable().columns(0).search($(this).val()).draw();
  			});

			$("#order_status").select2({
  				width: '140px'
  			}).on('change', function() {
				$('#orders').DataTable().columns(3).search($(this).val()).draw();  		
  			});

  			$("#order_type").select2({
  				width: '150px'
  			}).on('change', function() {
				$('#orders').DataTable().columns(4).search($(this).val()).draw(); 
  			});

  			$('#search_did').keyup(function(e) {
  				var val = $(this).val();

  				if(timer) {
  					clearTimeout(timer);
  				}
				
				timer = setTimeout(didSearch, 400, val);
  			});

  			$('#orders').DataTable({
				resposive: true,
				"sDom": '<"top"l>rt<"bottom"ip><"clear">',
				"lengthMenu": [ [5, 10, 25, 50, 100, -1], [5, 10, 25, 50, 100, "All"] ],
				"displayLength": 25	,
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
				    			case 'Completed':
				    				$(td).html('<span class="label label-success">Completed</span>');
				    			break;
				    			case 'Partially Fullfilled':
				    				$(td).html('<span class="label label-warning">Partially Fullfilled</span>');
				    			break;
				    			case 'Failed':
				    				$(td).html('<span class="label label-danger">Failed</span>');
				    			break;
				    			case 'Error':
				    				$(td).html('<span class="label label-danger">Error</span>');
				    			break;
				    		}
						}
					},
					/*{
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
					}*/
				],
			    "order": [[ 2, "desc" ]],
			    "processing": true,
			    "serverSide": true,
			    "ajax": {
			    	url: urls[0],
			    	method: 'post',
			    	data: {
			    		page: function() {
			    			return $('#orders').DataTable().page.info().page + 1;
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

		var didSearch = function(term) {
			$('#orders').DataTable().columns(6).search(term).draw(); 
		}

		var setUrls = function(arr) {
			urls = arr;
		};

		return {
			init: init,
			setUrls: setUrls
		};
			
	})(jQuery);

	App.CarrierOrdersHandler = (function($) {
		var urls, timer;

		var init = function() {
			$(document).on('click', 'a.close_modal', function() {
				$(this).parents('.modal').modal('hide');
			});

			$("#orders").on('click', '.clickable-row', function() {
        		window.document.location = $(this).data("href");
    		});

			$("#order_status").select2({
  				width: '140px'
  			}).on('change', function() {
				$('#orders').DataTable().columns(3).search($(this).val()).draw();  		
  			});

  			$("#order_type").select2({
  				width: '150px'
  			}).on('change', function() {
				$('#orders').DataTable().columns(0).search($(this).val()).draw(); 
  			});

  			$('#search_did').keyup(function(e) {
  				var val = $(this).val();

  				if(timer) {
  					clearTimeout(timer);
  				}
				
				timer = setTimeout(didSearch, 400, val);
  			});

  			$('#orders').DataTable({
				resposive: true,
				"sDom": '<"top"l>rt<"bottom"ip><"clear">',
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
				    			case 'Pending':
				    				$(td).html('<span class="label label-default">Pending</span>');
				    			break;
				    			case 'Completed':
				    				$(td).html('<span class="label label-success">Completed</span>');
				    			break;
				    			case 'Partially Fullfilled':
				    				$(td).html('<span class="label label-warning">Partially Fullfilled</span>');
				    			break;
				    			case 'Failed':
				    				$(td).html('<span class="label label-danger">Failed</span>');
				    			break;
				    			case 'Error':
				    				$(td).html('<span class="label label-danger">Error</span>');
				    			break;
				    		}
						}
					},
					/*{
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
					}*/
				],
			    "order": [[ 2, "desc" ]],
			    "processing": true,
			    "serverSide": true,
			    "ajax": {
			    	url: urls[0],
			    	method: 'post',
			    	data: {
			    		page: function() {
			    			return $('#orders').DataTable().page.info().page + 1;
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

		var didSearch = function(term) {
			$('#orders').DataTable().columns(5).search(term).draw(); 
		}

		var setUrls = function(arr) {
			urls = arr;
		};

		return {
			init: init,
			setUrls: setUrls
		};
			
	})(jQuery);

});
