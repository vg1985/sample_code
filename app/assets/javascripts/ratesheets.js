//= require bootstrap.min
//= require modernizr.min
//= require toggles.min
//= require retina.min
//= require jquery.cookies
//= require jquery.validate.min
//= require select2.min
//= require jquery.datatables.min
//= require jquery.gritter.min
//= require jquery.datetimepicker
//= require custom
//= require_self

var App = App || {};

jQuery(document).ready(function() {
	App.RatesheetFormHandler = (function($) {
		var urls;

		var init = function(settings) {
			$("#lrn_activation_tgl").toggles({ on: settings[0] , checkbox: $("#lrn_activation_tgl_chkbox"), 'event': 'toggle', text: {on: "Yes", off: "No"}});

			$(".select2").select2({
				width: '90%',
			});

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
					"rate_sheet[name]" : {
						required : true,
						minlength: 3,
						maxlength: 25,
						remote : {
							url : urls[0],
							type : "get",
						}
					},
				},
				messages : {
					"rate_sheet[name]" : {
						remote : "This rate sheet name already exists with us."
					}
				}
			};

			$editFormValidator = $('#editRatesheetForm').validate($.extend(true, {}, validationOptions, {
				rules: {
					"rate_sheet[name]": {remote: {
						data: {id: $('#rate_sheet_id').val()}
					}}
				}
			}));
			
			$newFormValidator = $('#newRatesheetForm').validate($.extend(true, {}, validationOptions, {}));
		};

		var setUrls = function(arr) {
			urls = arr;
		};

		return {
			init: init,
			setUrls: setUrls
		}
	})(jQuery);

	App.AdminRateSheetListHandler = (function($) {
		var urls;

		var init = function() {
			$(document).on('click', 'a.close_modal', function() {
				$(this).parents('.modal').modal('hide');					
			});

			$("#lrn_select").select2({
  				width: '75%'
  			}).on('change', function() {
				$('#rate_sheets_table').DataTable().columns(2).search($(this).val()).draw();
  			});


			$("#jurisdiction_select").select2({
  				width: '75%'
  			}).on('change', function() {
				$('#rate_sheets_table').DataTable().columns(3).search($(this).val()).draw();
  			});

			$('table#rate_sheets_table').on('click', '.ratesheet_destroy', function() {
				destroy_trunk = $(this).data('ratesheet-id');

				$('.delete-ratesheet-confirm-dlg').modal('show');

				return false;
			});

			$('#del_ratesheet_confirm_ok').click(function () {
				var link = "a#ratesheet_" + destroy_trunk + "_destroy_link";
				$(link).click();
				
				$('.delete-ratesheet-confirm-dlg').modal('hide');
			});

			$('#rate_sheets_table').DataTable({
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
				    	"targets": 2,
				    	"createdCell": function (td, cellData, rowData, row, col) {
				    		if(cellData) {
				    			$(td).addClass('text-center').html('<span class="glyphicon glyphicon-ok text-success" title="Enabled"></span>');
				    		}
				    		else {
				    			$(td).addClass('text-center').html('<span class="glyphicon glyphicon-remove text-warning" title="Not Enabled"></span>');
				    		}
							
						}
					},
					{
				    	"targets": 5,
				    	"createdCell": function (td, cellData, rowData, row, col) {
				    		$(td).html(cellData.truncate(40)).attr('title', cellData);
						}
					},
					{
						"targets": 6,
						"createdCell": function (td, cellData, rowData, row, col) {
							innerHtml = '';
							innerHtml += ' <a class="btn btn-default btn-xs" title="View" href="/rate_sheets/'+ cellData +'"><span class="glyphicon glyphicon-eye-open"></span></a>';
							innerHtml += ' <a class="btn btn-default btn-xs" title="Modify" href="/rate_sheets/'+ cellData +'/edit"><span class="glyphicon glyphicon-edit"></span></a>';
							innerHtml += ' <a href="#" rel="nofollow" data-ratesheet-id="'+ cellData +'" title="Delete" class="btn btn-danger btn-xs ratesheet_destroy"><span class="glyphicon glyphicon-trash"></span></a> ';
							innerHtml += ' <a href="/rate_sheets/'+ cellData +'" rel="nofollow" data-remote="true" data-method="delete" id="ratesheet_'+ cellData +'_destroy_link"></a>';
							innerHtml += ' <a href="/rate_sheets/'+ cellData +'/user_actions" title="List User Actions" class="btn btn-default btn-xs"><span class="glyphicon glyphicon-list"></span></a> ';
				    		$(td).html(innerHtml);
						}
					}
				],
			    "order": [[ 0, "asc" ]],
			    "processing": true,
			    "serverSide": true,
			    "ajax": {
			    	url: urls[0],
			    	method: 'post',
			    	data: {
			    		page: function() {
			    			return $('#rate_sheets_table').DataTable().page.info().page + 1;
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
			    }
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

	App.AdminRateSheetDataHandler = (function($) {
		var urls, valuesBuffer = [], delete_rate, rate_sheet_id, blank_rows;
		var bufferUsjDefaultValues =  ['', '', 'USA', '0', '0', '0', '6', '6', '0', ''];
		var bufferNusjDefaultValues =  ['', '', 'USA', '0', '6', '6', '0', ''];
		var usaJurisdiction, timer, importCSVDropZone, bulk_operation = false;
		var tempDataObj;
		var $bulk_edit_spinners = $('.bulk-edit-spinner');

		var init = function(seedArray) {
			usaJurisdiction = seedArray[1];
			rate_sheet_id = seedArray[0];
			blank_rows = seedArray[2];

			App.nav.collapseLeftNav();

			$(document).on('click', 'a.close_modal', function() {
				$(this).parents('.modal').modal('hide');
				bulk_operation = false;				
			});

			$('.select2').select2({
  				width: '100%'
  			});

			$(document).on('click', '#ratesheet_data_table th:not(".no-sort")', function() {
				var $el = $(this);
				var col = $el.data('col')
				var order = col + " ASC";

				if($el.hasClass('sorting')){
					$el.removeClass('sorting').addClass('sorting_asc');
				}
				else if($el.hasClass('sorting_asc')) {
					$el.removeClass('sorting_asc').addClass('sorting_desc');
					order = col + " DESC";
				}
				else {
					$el.removeClass('sorting_desc').addClass('sorting_asc');
				}

				data = { 'order': order, 'q': $('#global_search_q').val() };
				App.overlayModal.show();

				$.get('/rate_sheets/' + rate_sheet_id, data, null, 'script');
				$('#ratesheet_data_table th:not(".no-sort")').not($el).removeClass('sorting_asc sorting_desc').addClass('sorting');
			});

			$('#per_page').change(function() {
				var $el = $(this);

				if($el.val() > 0) {
					App.overlayModal.show();
					data = { 'per_page': $el.val(), 'q': $('#global_search_q').val() };
					$.get('/rate_sheets/' + rate_sheet_id, data, null, 'script');
				}
			});

			$(document).on('click', 'a#insert_anyway_link', function() {
				//console.log(tempDataObj);
				var dataObj = tempDataObj;
				App.overlayModal.show();
				if(dataObj.id) {
					$.ajax({
						url: '/rates/' + tempDataObj.id,
						dataType: 'script',
						data: dataObj,
						method: 'put'
					});
				}
				else {
					$.ajax({
						async: true,
						url: '/rates',
						dataType: 'script',
						data: dataObj,
						method: 'post'
					});	
				}
			});

			$('#decimal_precision_spinner').spinner({
				numberFormat: "n",
				step: 1,
				min: 1,
				max: 6,
				value: 6
			});

			$('.bulk-edit-select2').select2({
  				width: '100%'
  			}).on('change', function() {
  				var val = $(this).val();

  				if ($(this).data('spinner')) {
  					var sel = $(this).data('spinner');
  					var $spinner1 = $('#' + sel + '_nmul_spinner');
  					var $spinner2 = $('#' + sel + '_mul_spinner');

	  				if($.trim(val) == '') {
	  					$('#' + sel + '_nmul_spinner_cont').show();
	  					$('#' + sel + '_mul_spinner_cont').hide();
	  					$spinner1.spinner('disable').spinner('value', '');
	  					$spinner2.spinner('disable').spinner('value', '');
	  				}
	  				else if(val == '4') {
	  					$('#' + sel + '_nmul_spinner_cont').hide();
	  					$('#' + sel + '_mul_spinner_cont').show();
	  					$spinner1.spinner('enable').spinner('value', '');
	  					$spinner2.spinner('enable').spinner('value', '');
	  				}
	  				else {
	  					$('#' + sel + '_nmul_spinner_cont').show();
	  					$('#' + sel + '_mul_spinner_cont').hide();
	  					$spinner1.spinner('enable').spinner('value', '');
	  					$spinner2.spinner('enable').spinner('value', '');
	  				}
  				}

  				if ($(this).data('dtpicker')) {
  					var $dtpicker = $('#' + $(this).data('dtpicker'));
	  				if($.trim(val) == '') {
	  					$dtpicker.attr('disabled', true).val('');
	  				}
	  				else {
	  					$dtpicker.attr('disabled', false);
	  				}
  				}
  				
  			});
  			
  			//$bulk_edit_spinners.spinner();
  			$('.bulk-edit-multiply-spinner').spinner({
  				numberFormat: "n",
				step: 1,
				min: 1,
				max: 100,
				value: ''
  			});

  			$('#setup_fee_val_nmul_spinner').spinner({
  				numberFormat: "n",
				step: 0.0001,
				min: 0.0001,
				max: 99.9999,
				value: ''
  			});

  			$('#decimal_rounding_val_nmul_spinner').spinner({
  				numberFormat: "n",
				step: 1,
				min: 1,
				max: 6,
				value: 6
  			});

  			$('#bill_start_val_nmul_spinner, #bill_increment_val_nmul_spinner, #bill_increment_val_nmul_spinner').spinner({
  				numberFormat: "n",
				step: 1,
				min: 1,
				max: 60,
				value: ''
  			});

  			$('#rate_val_nmul_spinner, #inter_rate_val_nmul_spinner, #intra_rate_val_nmul_spinner').spinner({
				numberFormat: "n",
				step: 0.000001,
				min: 0.000000,
				max: 99.999999,
				value: ''
			});

  			$bulk_edit_spinners.each(function() {
  				if($(this).hasClass('disable')) {
  					$(this).spinner('disable');	
  				}	
  			});

  			$('.bulk-edit-datetimepicker').datetimepicker({
				format:	'Y-m-d H:i',
				allowBlank: true,
			});

			$('#reset_bulk_edit').click(function() {
				$('.bulk_edit_errors').hide();
				$('.bulk-edit-select2').select2('val', '');

				$bulk_edit_spinners.each(function() {
					$(this).spinner('value', '');

	  				if($(this).hasClass('disable')) {
	  					$(this).spinner('disable');	
	  				}
  				});

  				$('.bulk-edit-datetimepicker').attr('disabled', true).val('');
			});

			$('.batch-edit-dlg').on('show.bs.modal', function(e) {
				$('#reset_bulk_edit').click();
				$('#bulk_edit_rate_ids').val('');
				$('#bulkedit_apply_all_btn').addClass('disabled');
				$('#bulkedit_apply_selected_btn').addClass('disabled');
				$('#iagreecb').attr('checked', false);
				//var url = $(e.relatedTarget).data('url');
			});

			$('#iagreecb').click(function() {
				$('#bulkedit_apply_all_btn').addClass('disabled');
				$('#bulkedit_apply_selected_btn').addClass('disabled');

				if($(this).is(':checked')) {
					$('#bulkedit_apply_all_btn').removeClass('disabled');

					if($("div.rate-sheet-container input.rate-cb:checkbox:checked").length > 0) {
						$('#bulkedit_apply_selected_btn').removeClass('disabled');
					}
				}
			});

			$('#bulkedit_apply_all_btn').click(function() {
				if(bulkEditFieldPresent() && validateBulkEditFields()) {
					App.overlayModal.show();
					$('form#bulk_edit_form').submit();
					$('.batch-edit-dlg').modal('hide');
				}
			});

			$('#bulkedit_apply_selected_btn').click(function() {
				if(bulkEditFieldPresent() && validateBulkEditFields()) {
					var selectedValues = new Array();

					if($("div.rate-sheet-container input.rate-cb:checkbox:checked").length > 0) {
						$("div.rate-sheet-container input.rate-cb:checkbox:checked").each(function() {
							selectedValues.push($(this).val());
						});
					}

					$('#bulk_edit_rate_ids').val(selectedValues);

					App.overlayModal.show();
					$('form#bulk_edit_form').submit();

					$('.batch-edit-dlg').modal('hide');
				}
			});

			$("div.rate-sheet-container").on('click', 'input.rate-cb', function() {
			    if ($(this).attr('checked')) {
			        $(this).parents('tr').addClass('checked');
			    } 
			    else {
			        $(this).parents('tr').removeClass('checked');
			    }
			});

			$("div.rate-sheet-container").on('click', '.result_select_all', function() {
				$("div.rate-sheet-container input.rate-cb:checkbox:not(:checked)").attr('checked', true);
				$('input.rate-cb').parents('tr').addClass('checked');
				toggleGroupButtons();
			});
			
			$("div.rate-sheet-container").on('click', '.result_deselect_all', function() {
				$("div.rate-sheet-container input.rate-cb:checkbox:checked").attr('checked', false);
				$('input.rate-cb').parents('tr').removeClass('checked');
				toggleGroupButtons();
			});
			
			$("div.rate-sheet-container").on('click', '.result_invert_sel', function() {
				$("div.rate-sheet-container input.rate-cb:checkbox").click();
				toggleGroupButtons();
			});

			$("div.rate-sheet-container").on('click', 'input.rate-cb:checkbox', function() {
				toggleGroupButtons();
			});

			$("div.rate-sheet-container").on('dblclick', 'tr.rate-static', function(e) {
				if ($('a.modify').hasClass('disabled')) {
					e.stopPropagation();
					return false;
				}

				if(!$(e.target).hasClass('no-dblclick')) {
					$(this).hide();
					$(this).next('tr.rate-fields').show();
					$('a.modify, #add_new_btn').addClass('disabled');
					readValues($(this));
					return;
				}

				e.stopPropagation();
			});

			$("div.rate-sheet-container").on('click', 'a.cancel-modify', function() {
				var id = $(this).data('id');
				$('tr#rate_fields_' + id).hide();
				$('tr#rate_static_' + id).show();
				$('.update_row').popover('hide');
				$('a.modify, #add_new_btn').removeClass('disabled');
				setValues($('tr#rate_fields_' + id), valuesBuffer);
			});

			$("div.rate-sheet-container").on('click', 'a.modify', function() {
				$('a.modify, #add_new_btn').addClass('disabled');
				
				var id = $(this).data('id');
				$('tr#rate_fields_' + id).show();
				$('tr#rate_static_' + id).hide();
				readValues($('tr#rate_static_' + id));
			});

			$("#add_new_btn").click(function() {
				$('.rate-new-fields').show();
				$(this).addClass('disabled');
				$('a.modify').addClass('disabled');

				if (usaJurisdiction) {
					valuesBuffer = bufferUsjDefaultValues;
				}
				else {
					valuesBuffer = bufferNusjDefaultValues;
				}
				
			});

			$('a.cancel-new').click(function() {
				$('.rate-new-fields').hide();
				$('a.modify, #add_new_btn').removeClass('disabled');
				setValues($('tr.rate-new-fields'), valuesBuffer);
			});

			$("div.rate-sheet-container").on('click', 'a.update_row', function() {
				var el = $(this);
				var id = el.data('id');
				
				var dataObj = getData($('tr#rate_fields_' + id));
				dataObj.id = id;

				if(validateData(dataObj, el)) {
					App.overlayModal.show();
					$.ajax({
						url: '/rates/' + id,
						dataType: 'script',
						data: dataObj,
						method: 'put'
					});
				}
			});

			$("div.rate-sheet-container").on('click', 'a.save_new_row', function() {
				var dataObj = getData($('tr.rate-new-fields'));
				
				dataObj['rate_sheet_id'] = rate_sheet_id;

				if(validateData(dataObj, $(this))) {
					App.overlayModal.show();
					$.ajax({
						async: true,
						url: '/rates',
						dataType: 'script',
						data: dataObj,
						method: 'post'
					});
				}
			});

			$('div.rate-sheet-container').on('click', '.rate-delete', function() {
				delete_rate = $(this).data('pk');
				$('.delete-rate-confirm-dlg').modal('show');
				return false;
			});

			$('#del_rate_confirm_ok').click(function () {
				App.overlayModal.show();
				
				if(bulk_operation) {
					$('form#selected_rates_form').submit();
				}
				else {
					var link = "a#rate_" + delete_rate + "_destroy_link";
					$(link).click();
				}
				
				$('.delete-rate-confirm-dlg').modal('hide');
				bulk_operation = false;
			});

			$('button.bulk-operation').click(function() {
				bulk_operation = true;
				$('form#selected_rates_form').attr('action', $(this).data('url'));
			});

			$('#rate_page_links').on('click', 'a', function() {
				App.overlayModal.show();
			})

			$("#sample_download_btn, #user_actions_btn").click(function() {
				window.location.href = $(this).data('url');
			});

			$("#export_btn").click(function() {
				if(!blank_rows) {
					url = $(this).data('url');
					if($.trim($('#global_search_q').val()) != '') {
						url += '?q=' + $.trim($('#global_search_q').val());
					}

					window.location.href = url;	
				}
			});

			$('#import_btn').click(function() {
				importCSVDropZone.removeAllFiles();
			});

			$('#global_search_q').keyup(function(e) {
  				var val = $(this).val();

  				if(timer) {
  					clearTimeout(timer);
  				}
				
				timer = setTimeout(globalSearch, 800, val);
  			});
			
			initControls();
			initDropzone();
		};

		var bulkEditFieldPresent = function() {
			//return true;
			var selected = false;

			$('.bulk-edit-select2').each(function() {
				if($.trim($(this).val()) != '') {
					selected = true;
				}
			});
			
			return selected;
		}

		var globalSearch = function(val) {
			$.get(urls[1], {q: val}, null, 'script');	
		};

		readValues = function($parent) {
			valuesBuffer = new Array();

			$parent.find('td').each(function() {
				if(!$(this).hasClass('ronly')) {
					valuesBuffer.push($(this).text());
				}
			});

			console.log(valuesBuffer);
		};

		setValues = function($parent, values) {
			$parent.find('input.text-box').each(function(i) {
				$(this).val(valuesBuffer[i]);
			});

			$parent.find('.spinner').each(function(i) {
				$(this).spinner('value', valuesBuffer[i + 3]);
			});

			if(usaJurisdiction) {
				$parent.find('.datetimepicker').val(valuesBuffer[9]);	
			}
			else {
				$parent.find('.datetimepicker').val(valuesBuffer[7]);
			}
			
		};

		getData = function($parent) {
			data = {};

			$parent.find('input.text-box').each(function(i) {
				var el = $(this);
				data[el.attr('name')] = el.val();
			});

			$parent.find('.spinner').each(function(i) {
				var el = $(this);
				data[el.attr('name')] = el.spinner('value');
			});

			var eff_time = $parent.find('.datetimepicker');
			data[eff_time.attr('name')] = eff_time.val();

			return data;
		};

		setData = function($parent, values) {
			$parent.find('td').not('.ronly').each(function(i) {
				$(this).html(values[i]);
			});
		};

		validateBulkEditFields = function() {
			var error = false, value;
			var option;

			$('.bulk_edit_errors').hide();

			option = $('#bulk_edit_rate').val();

			if($.trim(option) != '') {
				if(option == '4') {
					value = $('#rate_val_mul_spinner').spinner('value');

					if(!(/^\d+$/.test(value)) || parseInt(value) > 100 || parseInt(value) < 1) {
						$('#rate_error').show();
						error = true;
					}	
				}
				else {
					value = $('#rate_val_nmul_spinner').spinner('value');

					if(!$.isNumeric(value) || parseFloat(value) < 0 || 
						parseFloat(value) > 99.999999 ||  (parseFloat(value) > 0 && parseFloat(value) < 0.000001)) {
						$('#rate_error').show();
						error = true;
					}											
				}
			}

			if (usaJurisdiction) {
				option = $('#bulk_edit_intra_rate').val();

				if($.trim(option) != '') {
					if(option == '4') {
						value = $('#intra_rate_val_mul_spinner').spinner('value');

						if(!(/^\d+$/.test(value)) || parseInt(value) > 100 || parseInt(value) < 1) {
							$('#intra_rate_error').show();
							error = true;
						}	
					}
					else {
						value = $('#intra_rate_val_nmul_spinner').spinner('value');

						if(!$.isNumeric(value) || parseFloat(value) < 0 || 
							parseFloat(value) > 99.999999 ||  (parseFloat(value) > 0 && parseFloat(value) < 0.000001)) {
							$('#intra_rate_error').show();
							error = true;
						}												
					}
				}

				option = $('#bulk_edit_inter_rate').val();

				if($.trim(option) != '') {
					if(option == '4') {
						value = $('#inter_rate_val_mul_spinner').spinner('value');

						if(!(/^\d+$/.test(value)) || parseInt(value) > 100 || parseInt(value) < 1) {
							$('#inter_rate_error').show();
							error = true;
						}	
					}
					else {
						value = $('#inter_rate_val_nmul_spinner').spinner('value');

						if(!$.isNumeric(value) || parseFloat(value) < 0 || 
							parseFloat(value) > 99.999999 ||  (parseFloat(value) > 0 && parseFloat(value) < 0.000001)) {
							$('#inter_rate_error').show();
							error = true;
						}													
					}
				}
			}

			if($('#bulk_edit_bill_start').val() != '') {
				value = $('#bill_start_val_nmul_spinner').spinner('value');

				if(!(/^\d+$/.test(value)) || parseInt(value) > 60 || parseInt(value) < 1) {
					$('#bill_start_error').show();
					error = true;
				}
			}

			if($('#bulk_edit_bill_increment').val() != '') {
				value = $('#bill_increment_val_nmul_spinner').spinner('value');

				if(!(/^\d+$/.test(value)) || parseInt(value) > 60 || parseInt(value) < 1) {
					$('#bill_inc_error').show();
					error = true;
				}
			}

			option = $('#bulk_edit_setup_fee').val();

			if($.trim(option) != '') {
				if(option == '4') {
					value = $('#setup_fee_val_mul_spinner').spinner('value');

					if(!(/^\d+$/.test(value)) || parseInt(value) > 100 || parseInt(value) < 1) {
						$('#setup_fee_error').show();
						error = true;
					}	
				}
				else {
					value = $('#setup_fee_val_nmul_spinner').spinner('value');

					if(!$.isNumeric(value) || parseFloat(value) < 0 || 
						parseFloat(value) > 99.9999 || (parseFloat(value) > 0 && parseFloat(value) < 0.0001)) {
						$('#setup_fee_error').show();
						error = true;
					}												
				}
			}

			if($('#bulk_edit_decimal_precision').val() != '') {
				value = $('#decimal_rounding_val_nmul_spinner').spinner('value');

				if(!(/^\d+$/.test(value)) || parseInt(value) > 6 || parseInt(value) < 1) {
					$('#precision_error').show();
					error = true;
				}
			}
			
			if($('#bulk_edit_effective_time').val() != '') {
				value = $('#effective_time_val').val();

				if(!(/^(19|20)\d\d-(0[1-9]|1[012])-(0[1-9]|[12][0-9]|3[01]) ([01]\d|2[0-3]):[0-5]\d$/.test(value))) {
					$('#effective_time_error').show();
					error = true;
				}
			}

			return !error;
		}

		validateData = function(dataObj, $popoverEl) {
			var popover = $popoverEl.data('bs.popover');
			var unique_error = false;
			var messages = new Array();

			$.each(dataObj, function(key, value) {
				switch(key) {
					case 'code':
						value = $.trim(value);
						if(!(/^\d+$/.test(value)) || value.length > 25) {
							messages.push('<li>Code</li>');
						}
						else {
							//var postData = {name: value, rid: rate_sheet_id, eff_time: dataObj.effective_time};
							var postData = {name: value, rid: rate_sheet_id};

							if(dataObj.id) {
								postData.id = dataObj.id;
							}

							$.ajax({
						        type: "GET",
						        async: false,
						        url: urls[0],
						        data: postData,
						        dataType: 'json',
						        success: function(response) {
						        	if(!response) {
						        		messages.push('<li>Code: Already exists for the effective time.</li>');	
						        		unique_error = true;
						        	}
						        }
						    });
						}
					break;
					case 'code_country':
						if($.trim(value).length > 10) {
							messages.push('<li>Code Country</li>');
						}
					break;
					case 'code_name':
						if($.trim(value).length > 25) {
							messages.push('<li>Name</li>');
						}
					break;
					case 'inter_rate':
						if(!$.isNumeric(value) || parseFloat(value) < 0 || 
							parseFloat(value) > 99.999999 || (parseFloat(value) > 0 && parseFloat(value) < 0.000001)) {
							messages.push('<li>Inter Rate</li>');
						}
					break;
					case 'intra_rate':
						if(!$.isNumeric(value) || parseFloat(value) < 0 || 
							parseFloat(value) > 99.999999 || (parseFloat(value) > 0 && parseFloat(value) < 0.000001)) {
							messages.push('<li>Intra Rate</li>');
						}
					break;
					case 'rate':
						if(!$.isNumeric(value) || parseFloat(value) < 0 || 
							parseFloat(value) > 99.999999 ||  (parseFloat(value) > 0 && parseFloat(value) < 0.000001)) {
							messages.push('<li>Rate</li>');
						}
					break;
					case 'bill_increment':
						if(!(/^\d+$/.test(value)) || parseInt(value) > 60 || parseInt(value) < 1) {
							messages.push('<li>Bill Increment</li>');	
						}
					break;
					case 'bill_start':
					if(!(/^\d+$/.test(value)) || parseInt(value) > 60 || parseInt(value) < 1) {
							messages.push('<li>Bill Start</li>');	
						}
					break;
					case 'setup_fee':
						if(!$.isNumeric(value) || parseFloat(value) < 0 || 
							parseFloat(value) > 99.9999 || (parseFloat(value) > 0 && parseFloat(value) < 0.0001)) {
							messages.push('<li>Setup Fee</li>');
						}
					break;
					case 'effective_time':
						if($.trim(value) == '' || !(/^(19|20)\d\d-(0[1-9]|1[012])-(0[1-9]|[12][0-9]|3[01]) ([01]\d|2[0-3]):[0-5]\d$/.test(value))) {
							messages.push('<li>Effective Time</li>')
						}
					break;
				}
			});

			if(messages.length > 0) {
				var btnTitle;
				var html = "<div class='small'><p>Following fields have error(s). Please hover over these fields to check the valid values.</p><ul class='text-danger'>";
				html += messages.join('');
				html += "</ul>";
				
				if(messages.length == 1 && unique_error) {
					tempDataObj = dataObj;
					
					if(dataObj.id) {
						btnTitle = 'Update Anyway';
					}
					else {
						btnTitle = 'Insert Anyway';
					}
					
					html += "<div class='text-center'><a href='javascript:void(0);' class='btn btn-info btn-xs' id='insert_anyway_link'>"+ btnTitle +"</a></div>";
				}

				html += "</div>";

				popover.options.content = html;
				
				$popoverEl.popover('show');
				setTimeout(function(){ $popoverEl.popover('hide'); }, 10000);

				return false;
			}
			
			return true;
		}

		var initControls = function() {
			$('.update_row, .save_new_row').popover({
				trigger: 'manual'
			});
			$('[data-toggle="tooltip"]').tooltip();
			$('.spinner').spinner();
			$('.datetimepicker').datetimepicker({
				format:	'Y-m-d H:i',
				allowBlank: false,
			});

			if(blank_rows) {
				$('#export_btn, #bulk_edit_btn').addClass('disabled');
			}
			else {
				$('#export_btn, #bulk_edit_btn').removeClass('disabled');	
			}
		};

		var toggleGroupButtons = function() {
			if ($("div.rate-sheet-container input.rate-cb:checkbox:checked").length > 0) {
				$('button.bulk-operation').removeClass('disabled');	
			}			
			else {
				$('button.bulk-operation').addClass('disabled');
			}
		};

		var initDropzone = function() {
			Dropzone.options.csvFile = false;
 
			importCSVDropZone = new Dropzone("div#csv_file",{
            //Dropzone.options.csv_file({
              url: urls[2],
              headers: {"X-CSRF-Token" : $('meta[name="csrf-token"]').attr('content')},
              maxFilesize: 20,
              filesizeBase: 1024,
              addRemoveLinks: true,
              uploadMultiple: false,
              maxFiles: 1,
              acceptedFiles: 'text/csv,.csv',
              dictDefaultMessage: "<h4>Drop File here</h4> or click here to upload.",
              dictMaxFilesExceeded: "Only one file can be uploaded.",
              init: function() {
              	this.on('sending', function(file, xhr, formData) {
              		formData.append('import_option', $('#import_option').val());
              		formData.append('decimal_precision', $('#decimal_precision_spinner').spinner('value'));
              	});

                this.on("success", function(file, response) { 
                  if (response.status == 'success') {
                  	window.location.href = response.url;
                  }
                });
              },
              fallback: function() {
                $('.done-btn').show();
              },
              forceFallback: false
        	});

			$(".done-btn").on('click', function() {
	            $('#upload_csv_file').submit();
	        })
		}

		var resetNewValues = function() {
			console.log(usaJurisdiction);
			if (usaJurisdiction) {
				setValues($('tr.rate-new-fields'), bufferUsjDefaultValues);
			}
			else {
				setValues($('tr.rate-new-fields'), bufferNusjDefaultValues);
			}
		};

		var setUrls = function(arr) {
			urls = arr;
		};

		var setBlankRows = function(val) {
			blank_rows = val;
		}

		return {
			init: init,
			setUrls: setUrls,
			setData: setData,
			setBlankRows: setBlankRows,
			resetNewValues: resetNewValues,
			initControls: initControls
		}
	})(jQuery);
});