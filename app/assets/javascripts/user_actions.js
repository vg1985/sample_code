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
	App.UserActionsHandler = (function($) {
		var urls, timer;

		var init = function() {
			var refreshDTTimeout;

  			$('#user_actions').DataTable({
				resposive: true,
				"sDom": '<"top"l>rt<"bottom"ip><"clear">',
				"lengthMenu": [ [5, 10, 25, 50, 100, -1], [5, 10, 25, 50, 100, "All"] ],
				"columnDefs":[
					{
			    	"targets" : 'no-sort',
			    	"orderable" : false,
			    	},
			    	{
				    	"targets": 6,
				    	"createdCell": function (td, cellData, rowData, row, col) {
				    		if($.trim(cellData) == '') {
				    			$(td).html('<a title="Download details" class="btn btn-primary btn-xs disabled" href="#"><span class="glyphicon glyphicon-download"></span></a>');
				    		}
				    		else {
				    			$(td).html('<a title="Download details" class="btn btn-primary btn-xs" href="' + cellData + '"><span class="glyphicon glyphicon-download"></span></a>');
				    		}
				    		
						}
					},
					{
						"targets": [4],
						"createdCell": function (td, cellData, rowData, row, col) {
				    		if(cellData.toLowerCase() == 'processing') {
				    			if(refreshDTTimeout)
				    				clearTimeout(refreshDTTimeout);

				    			refreshDTTimeout = setTimeout(function(){
									$('#user_actions').DataTable().draw();
								}, 10000);
				    		}	
				    	}
					},
					/*{
						"targets": 5,
						"createdCell": function (td, cellData, rowData, row, col) {
							innerHtml = '';
							innerHtml += ' <button class="btn btn-default btn-xs" title="Details" data-url="/payments/' + cellData[0] + '" data-toggle="modal" data-target=".view-payment-dlg"><span class="glyphicon glyphicon-eye-open"></span></button> ';
							innerHtml += ' <button class="btn btn-default btn-xs" data-url="/payments/' + cellData[0] + '/edit" title="Edit" data-toggle="modal" data-target=".edit-payment-dlg"><span class="glyphicon glyphicon-edit"></span></button> ';	
				    		$(td).html(innerHtml);
						}
					}*/
				],
			    "order": [[ 0, "desc" ]],
			    "processing": true,
			    "serverSide": true,
			    "ajax": {
			    	url: urls[0],
			    	method: 'post',
			    	data: {
			    		page: function() {
			    			return $('#user_actions').DataTable().page.info().page + 1;
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
			        var paginateRow = $('#user_actions_paginate');
			        var pageCount = Math.ceil((this.fnSettings().fnRecordsDisplay()) / this.fnSettings()._iDisplayLength);
			        if (pageCount > 1)  {
			            paginateRow.css("display", "block");
			        } else {
			            paginateRow.css("display", "none");
			        }
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
