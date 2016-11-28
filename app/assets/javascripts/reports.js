//= require bootstrap.min
//= require modernizr.min
//= require toggles.min
//= require retina.min
//= require jquery.cookies
//= require jquery.datatables.min
//= require jquery.validate.min
//= require select2.min
//= require moment
//= require bootstrap-datetimepicker
//= require custom
//= require_self

var App = App || {};

$(document).ready(function() {
	App.ProfitReportHandler = (function($) {
		var urls; 

		var init = function() {
			App.nav.collapseLeftNav();

			$(document).on('click', '.adv-crit', function(){
		      var t = $(this);
		      var p = t.closest('.panel');
		      if(!$(this).hasClass('maximize')) {
		         p.find('.panel-body').slideUp(200);

		         p.find('.adv-crit').each(function() {
		            t = jQuery(this);
		            t.addClass('maximize');
		            if(!t.hasClass('no-text-change')) {
		               t.html('&plus;');
		            }   
		         });
		      } 
		      else {
		         p.find('.panel-body').slideDown(200);

		         p.find('.adv-crit').each(function() {
		            t = $(this);
		            t.removeClass('maximize');
		            if(!t.hasClass('no-text-change')) {
		               t.html('&minus;');
		            }
		         });
		      }
		      return false;
		   });

			$('#include_all_chk').change(function() {
				App.overlayModal.show();
				$('#include_all').val($(this).is(':checked') ? 1 : 0);    
				$('#include_all_form').submit();
			});

			$(document).on ('click', 'a.export-link', function() {
				var format = $(this).data('format');
				$('form#adv_crit_form #format').val(format);
				$("form#adv_crit_form").removeAttr("data-remote");
  				$("form#adv_crit_form").removeData("remote").submit();
			});

			$('.submit-btn').click(function() {
				App.overlayModal.show();
				$('form#adv_crit_form #format').val('js');
				$('form#adv_crit_form').data("remote", true).submit();
			});

			$("#date_range_select").select2({
  				width: '100%'
  			}).on('change', function() {
				var value = $(this).val();
				var today = moment(new Date());

				switch(value) {
					case '0':
						$('#from_date, #to_date').attr("readonly", true);
						$('#from_date').val(today.format('YYYY-MM-DD 00:00:00'));
						$('#to_date').val(today.format('YYYY-MM-DD 23:59:59'));
					break;
					case '1':
						$('#from_date, #to_date').attr("readonly", true);
						$('#from_date').val(today.format('YYYY-MM-DD HH:00:00'));
						$('#to_date').val(today.format('YYYY-MM-DD HH:59:59'));
					break;
					case '2':
						var last_hour = today.subtract(1, 'h');
						$('#from_date, #to_date').attr("readonly", true);
						$('#from_date').val(last_hour.format('YYYY-MM-DD HH:00:00'));
						$('#to_date').val(last_hour.format('YYYY-MM-DD HH:59:59'));
					break;
					case '3':
						var yesterday = today.subtract(1, 'days');
						$('#from_date, #to_date').attr("readonly", true);
						$('#from_date').val(yesterday.format('YYYY-MM-DD 00:00:00'));
						$('#to_date').val(yesterday.format('YYYY-MM-DD 23:59:59'));
					break;
					case '4':
						$('#from_date, #to_date').attr("readonly", true);
						$('#from_date').val(today.startOf('isoweek').format('YYYY-MM-DD 00:00:00'));
						$('#to_date').val(today.endOf('isoweek').format('YYYY-MM-DD 23:59:59'));
					break;
					case '5':
						var last_week = today.subtract(1, 'weeks');
						$('#from_date, #to_date').attr("readonly", true);
						$('#from_date').val(last_week.startOf('isoweek').format('YYYY-MM-DD 00:00:00'));
						$('#to_date').val(last_week.endOf('isoweek').format('YYYY-MM-DD 23:59:59'));
					break;
					case '6':
						$('#from_date, #to_date').attr("readonly", true);
						$('#from_date').val(today.startOf('month').format('YYYY-MM-DD 00:00:00'));
						$('#to_date').val(today.endOf('month').format('YYYY-MM-DD 23:59:59'));
					break;
					case '7':
						var last_month = today.subtract(1, 'months');
						$('#from_date, #to_date').attr("readonly", true);
						$('#from_date').val(last_month.startOf('month').format('YYYY-MM-DD 00:00:00'));
						$('#to_date').val(last_month.endOf('month').format('YYYY-MM-DD 23:59:59'));
					break;
					case '8':
						$('#from_date, #to_date').attr("readonly", true);
						$('#from_date').val(today.format('YYYY-01-01 00:00:00'));
						$('#to_date').val(today.format('YYYY-12-31 23:59:59'));
					break;
					case '9':
						var last_year = today.subtract(1, 'years');
						$('#from_date, #to_date').attr("readonly", true);
						$('#from_date').val(last_year.format('YYYY-01-01 00:00:00'));
						$('#to_date').val(last_year.format('YYYY-12-31 23:59:59'));
					break;
					default:
						$('#from_date, #to_date').attr("readonly", false);
				}
  			});

  			$("#tz_select").select2({
  				width: '100%'
  			});

  			$("#report_type_select").select2({
  				width: '85%'
  			}).change(function() {
  				var value = $(this).val();

  				if(value == 'term') {
  					$('#term_group_options').show();
  					$('#orig_group_options').hide();
  				}
  				else {
  					$('#term_group_options').hide();
  					$('#orig_group_options').show();
  				}
  			});

  			$("#ingress_carrier_select").select2({
  				width: '75%'
  			}).change(function() {
  				var value = $(this).val();
  				data = {
  						carrier_id: value, 
  						include_all: $('#include_all').is(':checked') ? 1 : 0
  				};
  				$.get('/reports/ingress_pin_down', data, null, 'script');
  			});

  			$("#egress_carrier_select").select2({
  				width: '75%'
  			}).change(function() {
  				var value = $(this).val();
  				data = {
  						carrier_id: value, 
  						include_all: $('#include_all').is(':checked') ? 1 : 0
  				};
  				$.get('/reports/egress_pin_down', data, null, 'script');
  			});

  			$("#group_option1_select, #group_option2_select").select2({
  				width: '75%'
  			}).on("select2-open", function(e) {
  				 $('ul.select2-results').css('max-height', '230px');
  			});

  			$('#ingress_trunk_select').select2({
  				width: '75%'
  			}).change(function() {
  				var value = $(this).val();
  				data = {
  						carrier_id: $('#ingress_carrier_select').val(), 
  						ingress_trunk_id: value,
  						include_all: $('#include_all').is(':checked') ? 1 : 0
  				};
  				$.get('/reports/ingress_pin_down', data, null, 'script');
  			});

  			$('#egress_trunk_select').select2({
  				width: '75%'
  			}).change(function() {
  				var value = $(this).val();
  				data = {
  						carrier_id: $('#egress_carrier_select').val(),
  						egress_trunk_id: value,
  						include_all: $('#include_all').is(':checked') ? 1 : 0
  				};
  				$.get('/reports/egress_pin_down', data, null, 'script');
  			});;

  			$('#ingress_rate_select').select2({
  				width: '75%'
  			});

  			$('#egress_rate_select').select2({
  				width: '75%'
  			});

  			$('#ingress_techprefix_select').select2({
  				width: '75%'
  			});

  			$('#egress_techprefix_select').select2({
  				width: '75%'
  			});

  			$('#ingress_routing_select').select2({
  				width: '75%'
  			});

  			$('#from_date').datetimepicker({
  				format: 'YYYY-MM-DD HH:mm:ss'
  			});

  			$('#to_date').datetimepicker({
  				format: 'YYYY-MM-DD HH:mm:ss',
  				useCurrent: false
  			});

  			$("#from_date").on("dp.change", function (e) {
  				var to_date = $('#to_date').val();
  				var from_date = $('#from_date').val();

  				if(e.date == null) {
  					$('#from_date').val($('#to_date').val());
  				}
  				else {
  					if(moment(from_date).isAfter(to_date)) {
  						$('#to_date').val($('#from_date').val());
  					}
  					
  					$('#to_date').data("DateTimePicker").minDate(e.date);	
  				}
	       	});

	       	$("#to_date").on("dp.change", function (e) {
	       		var to_date = $('#to_date').val();
    				var from_date = $('#from_date').val();
    				
  	       		if(e.date == null) {
					$('#to_date').val($('#from_date').val());
				}
				else {
					if(moment(to_date).isBefore(from_date)) {
						$('#from_date').val($('#to_date').val());
					}

					$('#from_date').data("DateTimePicker").maxDate(e.date);
				}
	       });
		};

		var setUrls = function(arr) {
			urls = arr;
		};

		var minimizeFilter = function() {
			var $el = $('.panel-heading a.adv-crit');
			if(!$el.hasClass('maximize')) {
				$el.click();	
			}
		};

		var initDatatable = function(selector) {
			$(selector).dataTable({
				resposive: true,
				"lengthMenu": [ [10, 25, 50, 100, -1], [10, 25, 50, 100, "All"] ],
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
			    }
			});
		};

		return {
			init: init,
			setUrls: setUrls,
			minimizeFilter: minimizeFilter,
			initDatatable: initDatatable
		};
	})(jQuery);

	App.SummaryReportHandler = (function($) {
		var urls; 

		var init = function() {
			App.nav.collapseLeftNav();

			$(document).on('click', '.adv-crit', function(){
		      var t = $(this);
		      var p = t.closest('.panel');
		      if(!$(this).hasClass('maximize')) {
		         p.find('.panel-body').slideUp(200);

		         p.find('.adv-crit').each(function() {
		            t = jQuery(this);
		            t.addClass('maximize');
		            if(!t.hasClass('no-text-change')) {
		               t.html('&plus;');
		            }   
		         });
		      } 
		      else {
		         p.find('.panel-body').slideDown(200);

		         p.find('.adv-crit').each(function() {
		            t = $(this);
		            t.removeClass('maximize');
		            if(!t.hasClass('no-text-change')) {
		               t.html('&minus;');
		            }
		         });
		      }
		      return false;
		   });

			$('#include_all_chk').change(function() {
				App.overlayModal.show();
				$('#include_all').val($(this).is(':checked') ? 1 : 0);    
				$('#include_all_form').submit();
			});

			$(document).on ('click', 'a.export-link', function() {
				var format = $(this).data('format');
				$('form#adv_crit_form #format').val(format);
				$("form#adv_crit_form").removeAttr("data-remote");
  				$("form#adv_crit_form").removeData("remote").submit();
			});

			$('.submit-btn').click(function() {
				App.overlayModal.show();
				$('form#adv_crit_form #format').val('js');
				$('form#adv_crit_form').data("remote", true).submit();
			});

			$("#date_range_select").select2({
  				width: '100%'
  			}).on('change', function() {
				var value = $(this).val();
				var today = moment(new Date());

				switch(value) {
					case '0':
						$('#from_date, #to_date').attr("readonly", true);
						$('#from_date').val(today.format('YYYY-MM-DD 00:00:00'));
						$('#to_date').val(today.format('YYYY-MM-DD 23:59:59'));
					break;
					case '1':
						$('#from_date, #to_date').attr("readonly", true);
						$('#from_date').val(today.format('YYYY-MM-DD HH:00:00'));
						$('#to_date').val(today.format('YYYY-MM-DD HH:59:59'));
					break;
					case '2':
						var last_hour = today.subtract(1, 'h');
						$('#from_date, #to_date').attr("readonly", true);
						$('#from_date').val(last_hour.format('YYYY-MM-DD HH:00:00'));
						$('#to_date').val(last_hour.format('YYYY-MM-DD HH:59:59'));
					break;
					case '3':
						var yesterday = today.subtract(1, 'days');
						$('#from_date, #to_date').attr("readonly", true);
						$('#from_date').val(yesterday.format('YYYY-MM-DD 00:00:00'));
						$('#to_date').val(yesterday.format('YYYY-MM-DD 23:59:59'));
					break;
					case '4':
						$('#from_date, #to_date').attr("readonly", true);
						$('#from_date').val(today.startOf('isoweek').format('YYYY-MM-DD 00:00:00'));
						$('#to_date').val(today.endOf('isoweek').format('YYYY-MM-DD 23:59:59'));
					break;
					case '5':
						var last_week = today.subtract(1, 'weeks');
						$('#from_date, #to_date').attr("readonly", true);
						$('#from_date').val(last_week.startOf('isoweek').format('YYYY-MM-DD 00:00:00'));
						$('#to_date').val(last_week.endOf('isoweek').format('YYYY-MM-DD 23:59:59'));
					break;
					case '6':
						$('#from_date, #to_date').attr("readonly", true);
						$('#from_date').val(today.startOf('month').format('YYYY-MM-DD 00:00:00'));
						$('#to_date').val(today.endOf('month').format('YYYY-MM-DD 23:59:59'));
					break;
					case '7':
						var last_month = today.subtract(1, 'months');
						$('#from_date, #to_date').attr("readonly", true);
						$('#from_date').val(last_month.startOf('month').format('YYYY-MM-DD 00:00:00'));
						$('#to_date').val(last_month.endOf('month').format('YYYY-MM-DD 23:59:59'));
					break;
					case '8':
						$('#from_date, #to_date').attr("readonly", true);
						$('#from_date').val(today.format('YYYY-01-01 00:00:00'));
						$('#to_date').val(today.format('YYYY-12-31 23:59:59'));
					break;
					case '9':
						var last_year = today.subtract(1, 'years');
						$('#from_date, #to_date').attr("readonly", true);
						$('#from_date').val(last_year.format('YYYY-01-01 00:00:00'));
						$('#to_date').val(last_year.format('YYYY-12-31 23:59:59'));
					break;
					default:
						$('#from_date, #to_date').attr("readonly", false);
				}
  			});

  			$("#tz_select").select2({
  				width: '100%'
  			});

  			$("#report_type_select").select2({
  				width: '85%'
  			}).change(function() {
  				var value = $(this).val();

  				if(value == 'term') {
  					$('#term_group_options').show();
  					$('#orig_group_options').hide();
  				}
  				else {
  					$('#term_group_options').hide();
  					$('#orig_group_options').show();
  				}
  			});

  			$("#ingress_carrier_select").select2({
  				width: '75%'
  			}).change(function() {
  				var value = $(this).val();
  				data = {
  						carrier_id: value, 
  						include_all: $('#include_all').is(':checked') ? 1 : 0
  				};
  				$.get('/reports/ingress_pin_down', data, null, 'script');
  			});

  			$("#egress_carrier_select").select2({
  				width: '75%'
  			}).change(function() {
  				var value = $(this).val();
  				data = {
  						carrier_id: value, 
  						include_all: $('#include_all').is(':checked') ? 1 : 0
  				};
  				$.get('/reports/egress_pin_down', data, null, 'script');
  			});

  			$("#group_option1_select, #group_option2_select").select2({
  				width: '75%'
  			}).on("select2-open", function(e) {
  				 $('ul.select2-results').css('max-height', '230px');
  			});;

  			$('#ingress_trunk_select').select2({
  				width: '75%'
  			}).change(function() {
  				var value = $(this).val();
  				data = {
  						carrier_id: $('#ingress_carrier_select').val(), 
  						ingress_trunk_id: value,
  						include_all: $('#include_all').is(':checked') ? 1 : 0
  				};
  				$.get('/reports/ingress_pin_down', data, null, 'script');
  			});

  			$('#egress_trunk_select').select2({
  				width: '75%'
  			}).change(function() {
  				var value = $(this).val();
  				data = {
  						carrier_id: $('#egress_carrier_select').val(),
  						egress_trunk_id: value,
  						include_all: $('#include_all').is(':checked') ? 1 : 0
  				};
  				$.get('/reports/egress_pin_down', data, null, 'script');
  			});;

  			$('#ingress_rate_select').select2({
  				width: '75%'
  			});

  			$('#egress_rate_select').select2({
  				width: '75%'
  			});

  			$('#ingress_techprefix_select').select2({
  				width: '75%'
  			});

  			$('#egress_techprefix_select').select2({
  				width: '75%'
  			});

  			$('#ingress_routing_select').select2({
  				width: '75%'
  			});

  			$('#from_date').datetimepicker({
  				format: 'YYYY-MM-DD HH:mm:ss'
  			});

  			$('#to_date').datetimepicker({
  				format: 'YYYY-MM-DD HH:mm:ss',
  				useCurrent: false
  			});

  			$("#from_date").on("dp.change", function (e) {
  				var to_date = $('#to_date').val();
  				var from_date = $('#from_date').val();

  				if(e.date == null) {
  					$('#from_date').val($('#to_date').val());
  				}
  				else {
  					if(moment(from_date).isAfter(to_date)) {
  						$('#to_date').val($('#from_date').val());
  					}
  					
  					$('#to_date').data("DateTimePicker").minDate(e.date);	
  					
  					
  				}
	       	});

	       	$("#to_date").on("dp.change", function (e) {
	       		var to_date = $('#to_date').val();
    				var from_date = $('#from_date').val();
    				
  	       		if(e.date == null) {
    					$('#to_date').val($('#from_date').val());
    				}
    				else {
    					if(moment(to_date).isBefore(from_date)) {
    						$('#from_date').val($('#to_date').val());
    					}

    					$('#from_date').data("DateTimePicker").maxDate(e.date);
    				}
	       });
		};

		var setUrls = function(arr) {
			urls = arr;
		}

		var minimizeFilter = function() {
			var $el = $('.panel-heading a.adv-crit');
			if(!$el.hasClass('maximize')) {
				$el.click();	
			}
		}

		return {
			init: init,
			setUrls: setUrls,
			minimizeFilter: minimizeFilter
		};
	})(jQuery);

	App.DIDReportHandler = (function($) {
		var urls; 

		var init = function() {
			App.nav.collapseLeftNav();

			$(document).on('click', '.adv-crit', function(){
		      var t = $(this);
		      var p = t.closest('.panel');
		      if(!$(this).hasClass('maximize')) {
		         p.find('.panel-body').slideUp(200);

		         p.find('.adv-crit').each(function() {
		            t = jQuery(this);
		            t.addClass('maximize');
		            if(!t.hasClass('no-text-change')) {
		               t.html('&plus;');
		            }   
		         });
		      } 
		      else {
		         p.find('.panel-body').slideDown(200);

		         p.find('.adv-crit').each(function() {
		            t = $(this);
		            t.removeClass('maximize');
		            if(!t.hasClass('no-text-change')) {
		               t.html('&minus;');
		            }
		         });
		      }
		      return false;
		   });

			$('#include_all_chk').change(function() {
				App.overlayModal.show();
				$('#include_all').val($(this).is(':checked') ? 1 : 0);    
				$('#include_all_form').submit();
			});

			$(document).on ('click', 'a.export-link', function() {
				var format = $(this).data('format');
				$('form#adv_crit_form #format').val(format);
				$("form#adv_crit_form").removeAttr("data-remote");
  				$("form#adv_crit_form").removeData("remote").submit();
			});

			$('.submit-btn').click(function() {
				App.overlayModal.show();
				$('form#adv_crit_form #format').val('js');
				$('form#adv_crit_form').data("remote", true).submit();
			});

			$("#date_range_select").select2({
  				width: '100%'
  			}).on('change', function() {
				var value = $(this).val();
				var today = moment(new Date());

				switch(value) {
					case '0':
						$('#from_date, #to_date').attr("readonly", true);
						$('#from_date').val(today.format('YYYY-MM-DD 00:00:00'));
						$('#to_date').val(today.format('YYYY-MM-DD 23:59:59'));
					break;
					case '1':
						$('#from_date, #to_date').attr("readonly", true);
						$('#from_date').val(today.format('YYYY-MM-DD HH:00:00'));
						$('#to_date').val(today.format('YYYY-MM-DD HH:59:59'));
					break;
					case '2':
						var last_hour = today.subtract(1, 'h');
						$('#from_date, #to_date').attr("readonly", true);
						$('#from_date').val(last_hour.format('YYYY-MM-DD HH:00:00'));
						$('#to_date').val(last_hour.format('YYYY-MM-DD HH:59:59'));
					break;
					case '3':
						var yesterday = today.subtract(1, 'days');
						$('#from_date, #to_date').attr("readonly", true);
						$('#from_date').val(yesterday.format('YYYY-MM-DD 00:00:00'));
						$('#to_date').val(yesterday.format('YYYY-MM-DD 23:59:59'));
					break;
					case '4':
						$('#from_date, #to_date').attr("readonly", true);
						$('#from_date').val(today.startOf('isoweek').format('YYYY-MM-DD 00:00:00'));
						$('#to_date').val(today.endOf('isoweek').format('YYYY-MM-DD 23:59:59'));
					break;
					case '5':
						var last_week = today.subtract(1, 'weeks');
						$('#from_date, #to_date').attr("readonly", true);
						$('#from_date').val(last_week.startOf('isoweek').format('YYYY-MM-DD 00:00:00'));
						$('#to_date').val(last_week.endOf('isoweek').format('YYYY-MM-DD 23:59:59'));
					break;
					case '6':
						$('#from_date, #to_date').attr("readonly", true);
						$('#from_date').val(today.startOf('month').format('YYYY-MM-DD 00:00:00'));
						$('#to_date').val(today.endOf('month').format('YYYY-MM-DD 23:59:59'));
					break;
					case '7':
						var last_month = today.subtract(1, 'months');
						$('#from_date, #to_date').attr("readonly", true);
						$('#from_date').val(last_month.startOf('month').format('YYYY-MM-DD 00:00:00'));
						$('#to_date').val(last_month.endOf('month').format('YYYY-MM-DD 23:59:59'));
					break;
					case '8':
						$('#from_date, #to_date').attr("readonly", true);
						$('#from_date').val(today.format('YYYY-01-01 00:00:00'));
						$('#to_date').val(today.format('YYYY-12-31 23:59:59'));
					break;
					case '9':
						var last_year = today.subtract(1, 'years');
						$('#from_date, #to_date').attr("readonly", true);
						$('#from_date').val(last_year.format('YYYY-01-01 00:00:00'));
						$('#to_date').val(last_year.format('YYYY-12-31 23:59:59'));
					break;
					default:
						$('#from_date, #to_date').attr("readonly", false);
				}
  			});

  			$("#tz_select").select2({
  				width: '100%'
  			});

  			$("#did_carrier_select").select2({
  				width: '75%'
  			});
  			
  			$("#group_option_select").select2({
  				width: '75%'
  			}).on("select2-open", function(e) {
  				 $('ul.select2-results').css('max-height', '300px');
  			});

  			$('#from_date').datetimepicker({
  				format: 'YYYY-MM-DD HH:mm:ss'
  			});

  			$('#to_date').datetimepicker({
  				format: 'YYYY-MM-DD HH:mm:ss',
  				useCurrent: false
  			});

  			$("#from_date").on("dp.change", function (e) {
  				var to_date = $('#to_date').val();
  				var from_date = $('#from_date').val();

  				if(e.date == null) {
  					$('#from_date').val($('#to_date').val());
  				}
  				else {
  					if(moment(from_date).isAfter(to_date)) {
  						$('#to_date').val($('#from_date').val());
  					}
  					
  					$('#to_date').data("DateTimePicker").minDate(e.date);	
  				}
	       	});

	       	$("#to_date").on("dp.change", function (e) {
	       		var to_date = $('#to_date').val();
    				var from_date = $('#from_date').val();
    				
  	       		if(e.date == null) {
					$('#to_date').val($('#from_date').val());
				}
				else {
					if(moment(to_date).isBefore(from_date)) {
						$('#from_date').val($('#to_date').val());
					}

					$('#from_date').data("DateTimePicker").maxDate(e.date);
				}
	       });
		};

		var setUrls = function(arr) {
			urls = arr;
		};

		var minimizeFilter = function() {
			var $el = $('.panel-heading a.adv-crit');
			if(!$el.hasClass('maximize')) {
				$el.click();	
			}
		};

		var initDatatable = function(selector) {
			$(selector).dataTable({
				resposive: true,
				"lengthMenu": [ [10, 25, 50, 100, -1], [10, 25, 50, 100, "All"] ],
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
			    }
			});
		};

		return {
			init: init,
			setUrls: setUrls,
			minimizeFilter: minimizeFilter,
			initDatatable: initDatatable
		};
	})(jQuery);

	App.CdrSearchReportHandler = (function($) {
		var urls; 

		var init = function() {
			App.nav.collapseLeftNav();
			
			$(document).on('click', '.adv-crit', function(){
		      var t = $(this);
		      var p = t.closest('.panel');

		      if(!$(this).hasClass('maximize')) {
		         p.find('.panel-body').slideUp(200);

		         p.find('.adv-crit').each(function() {
		            t = jQuery(this);
		            t.addClass('maximize');
		            if(!t.hasClass('no-text-change')) {
		               t.html('&plus;');
		            }   
		         });
		      } 
		      else {
		         p.find('.panel-body').slideDown(200);

		         p.find('.adv-crit').each(function() {
		            t = $(this);
		            t.removeClass('maximize');
		            if(!t.hasClass('no-text-change')) {
		               t.html('&minus;');
		            }
		         });
		      }
		      return false;
		   	});

		   	$(document).on('click', '#reports_table th:not(".no-sort"), .paginate_button', function() {
		   		App.overlayModal.show();
		   	});

			$('#include_all_chk').change(function() {
				App.overlayModal.show();
				$('#include_all').val($(this).is(':checked') ? 1 : 0);
				$('#include_all_form').submit();
			});

			$(document).on ('click', 'a.export-link', function() {
				var format = $(this).data('format');
				$('input#page_action').val('onscreen');
				$('form#adv_crit_form #format').val(format);
				$("form#adv_crit_form").removeAttr("data-remote");
  				$("form#adv_crit_form").removeData("remote").submit();
			});

			$('.submit-btn').click(function() {
				App.overlayModal.show();
				
				$('input#page_action').val($(this).data('action'));
				$('form#adv_crit_form #format').val('js');
				$('form#adv_crit_form').data("remote", true).submit();
			});

			$("#date_range_select").select2({
  				width: '100%'
  			}).on('change', function() {
				var value = $(this).val();
				var today = moment(new Date());

				switch(value) {
					case '0':
						$('#from_date, #to_date').attr("readonly", true);
						$('#from_date').val(today.format('YYYY-MM-DD 00:00:00'));
						$('#to_date').val(today.format('YYYY-MM-DD 23:59:59'));
					break;
					case '1':
						$('#from_date, #to_date').attr("readonly", true);
						$('#from_date').val(today.format('YYYY-MM-DD HH:00:00'));
						$('#to_date').val(today.format('YYYY-MM-DD HH:59:59'));
					break;
					case '2':
						var last_hour = today.subtract(1, 'h');
						$('#from_date, #to_date').attr("readonly", true);
						$('#from_date').val(last_hour.format('YYYY-MM-DD HH:00:00'));
						$('#to_date').val(last_hour.format('YYYY-MM-DD HH:59:59'));
					break;
					case '3':
						var yesterday = today.subtract(1, 'days');
						$('#from_date, #to_date').attr("readonly", true);
						$('#from_date').val(yesterday.format('YYYY-MM-DD 00:00:00'));
						$('#to_date').val(yesterday.format('YYYY-MM-DD 23:59:59'));
					break;
					case '4':
						$('#from_date, #to_date').attr("readonly", true);
						$('#from_date').val(today.startOf('isoweek').format('YYYY-MM-DD 00:00:00'));
						$('#to_date').val(today.endOf('isoweek').format('YYYY-MM-DD 23:59:59'));
					break;
					case '5':
						var last_week = today.subtract(1, 'weeks');
						$('#from_date, #to_date').attr("readonly", true);
						$('#from_date').val(last_week.startOf('isoweek').format('YYYY-MM-DD 00:00:00'));
						$('#to_date').val(last_week.endOf('isoweek').format('YYYY-MM-DD 23:59:59'));
					break;
					case '6':
						$('#from_date, #to_date').attr("readonly", true);
						$('#from_date').val(today.startOf('month').format('YYYY-MM-DD 00:00:00'));
						$('#to_date').val(today.endOf('month').format('YYYY-MM-DD 23:59:59'));
					break;
					case '7':
						var last_month = today.subtract(1, 'months');
						$('#from_date, #to_date').attr("readonly", true);
						$('#from_date').val(last_month.startOf('month').format('YYYY-MM-DD 00:00:00'));
						$('#to_date').val(last_month.endOf('month').format('YYYY-MM-DD 23:59:59'));
					break;
					case '8':
						$('#from_date, #to_date').attr("readonly", true);
						$('#from_date').val(today.format('YYYY-01-01 00:00:00'));
						$('#to_date').val(today.format('YYYY-12-31 23:59:59'));
					break;
					case '9':
						var last_year = today.subtract(1, 'years');
						$('#from_date, #to_date').attr("readonly", true);
						$('#from_date').val(last_year.format('YYYY-01-01 00:00:00'));
						$('#to_date').val(last_year.format('YYYY-12-31 23:59:59'));
					break;
					default:
						$('#from_date, #to_date').attr("readonly", false);
				}
  			});
			
  			$("#tz_select").select2({
  				width: '100%'
  			});

  			/*$("#cdr_template_select").select2({
  				width: '85%'
  			}).change(function() {
  				App.overlayModal.show();
  				var value = $(this).val();
  				window.location.href = urls[1] + '?filter=' + value;
  			});*/

  			$('.template-name').click(function() {
  				App.overlayModal.show();
  				var value = $(this).data('template-id');
  				window.location.href = urls[1] + '?filter=' + value;
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
					App.overlayModal.show();
					$('.save-template-dlg').modal('hide');
					$('#search_template_query').val($('#adv_crit_form').serialize());
					$.rails.handleRemote($(form));
				},
				rules : {
					"search_template[name]" : {
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
					"search_template[name]" : {
						remote : "This template name already exists with us."
					}
				}
			};

			$('#save_template_form').validate(validationOptions);

  			$("#ingress_carrier_select").select2({
  				width: '75%'
  			}).change(function() {
  				var value = $(this).val();
  				data = {
  						carrier_id: value, 
  						include_all: $('#include_all').is(':checked') ? 1 : 0
  				};
  				$.get('/reports/ingress_pin_down', data, null, 'script');
  			});

  			$("#egress_carrier_select").select2({
  				width: '75%'
  			}).change(function() {
  				var value = $(this).val();
  				data = {
  						carrier_id: value, 
  						include_all: $('#include_all').is(':checked') ? 1 : 0
  				};
  				$.get('/reports/egress_pin_down', data, null, 'script');
  			});

  			$("#group_option1_select, #group_option2_select").select2({
  				width: '75%'
  			});

  			$('#ingress_trunk_select').select2({
  				width: '75%'
  			}).change(function() {
  				var value = $(this).val();
  				data = {
  						carrier_id: $('#ingress_carrier_select').val(), 
  						ingress_trunk_id: value,
  						include_all: $('#include_all').is(':checked') ? 1 : 0
  				};
  				$.get('/reports/ingress_pin_down', data, null, 'script');
  			});

  			$('#egress_trunk_select').select2({
  				width: '75%'
  			}).change(function() {
  				var value = $(this).val();
  				data = {
  						carrier_id: $('#egress_carrier_select').val(),
  						egress_trunk_id: value,
  						include_all: $('#include_all').is(':checked') ? 1 : 0
  				};
  				$.get('/reports/egress_pin_down', data, null, 'script');
  			});;

  			$('#sel_all_cols').click(function() {
  				$('.display-col').attr('checked', true);
  			});

  			$('#remove_all_cols').click(function() {
  				$('.display-col').attr('checked', false);
  			});

  			$('#invert_cols').click(function() {
  				var unchecked = $('.display-col').not(":checked");
  				$('.display-col:checked').attr('checked', false);
  				unchecked.attr('checked', true);
  			});
  			//$(".multiselect").multiselect();

  			$('#ingress_rate_select').select2({
  				width: '75%'
  			});

  			$('#egress_rate_select').select2({
  				width: '75%'
  			});

  			$('#ingress_techprefix_select').select2({
  				width: '75%'
  			});

  			$('#egress_techprefix_select').select2({
  				width: '75%'
  			});

  			$('#duration_select').select2({
  				width: '75%'
  			});

  			$('#ingress_response_select').select2({
  				width: '75%'
  			});

  			$('#ringtime_select').select2({
  				width: '75%'
  			}).change(function() {
  				var value = $(this).val();
  				$('#custom_rt_field').hide();
  				if(value == '-1') {
  					$('#custom_rt_field').show();
  				}
  			});

  			$('#egress_response_select').select2({
  				width: '75%'
  			});

  			$('#sort_by_select').select2({
  				width: '100%',
  				placeholder: 'Please Select'
  			});

  			$('#from_date').datetimepicker({
  				format: 'YYYY-MM-DD HH:mm:ss'
  			});

  			$('#to_date').datetimepicker({
  				format: 'YYYY-MM-DD HH:mm:ss',
  				useCurrent: false
  			});

  			$("#from_date").on("dp.change", function (e) {
  				var to_date = $('#to_date').val();
  				var from_date = $('#from_date').val();

  				if(e.date == null) {
  					$('#from_date').val($('#to_date').val());
  				}
  				else {
  					if(moment(from_date).isAfter(to_date)) {
  						$('#to_date').val($('#from_date').val());
  					}
  					
  					$('#to_date').data("DateTimePicker").minDate(e.date);	
  					
  					
  				}
	       	});

	       	$("#to_date").on("dp.change", function (e) {
	       		var to_date = $('#to_date').val();
    				var from_date = $('#from_date').val();
    				
  	       		if(e.date == null) {
    					$('#to_date').val($('#from_date').val());
    				}
    				else {
    					if(moment(to_date).isBefore(from_date)) {
    						$('#from_date').val($('#to_date').val());
    					}

    					$('#from_date').data("DateTimePicker").maxDate(e.date);
    				}
	       });
		};

		var initDatatable = function(selector, total_records) {
			$(selector).dataTable({
				resposive: true,
				"sDom": '<"top"l>rt<"bottom"ip><"clear">',
				"lengthMenu": [ [25, 50, 100, 200], [25, 50, 100, 200] ],
				"displayLength": 25,
				"columnDefs":[{
			    	"targets" : 'no-sort',
			    	"orderable" : false,
			    }],
			    "order": [],
			    "processing": true,
			    "serverSide": true,
			    "deferLoading": total_records,
			    "ajax": {
			    	url: urls[2],
			    	method: 'post',
			    	data: {
			    		page: function() {
			    			return $('#reports_table').DataTable().page.info().page + 1;
			    		}
			    	}	
			    },
			    "language": {
					"paginate": {
						"previous": "<<",
						"next": ">>"
			        },
			        "search": ""
			    },
			    "fnDrawCallback": function() {
			    	App.overlayModal.hide();
			        var paginateRow = $(this).parent().children('div.dataTables_paginate');
			        var pageCount = Math.ceil((this.fnSettings().fnRecordsDisplay()) / this.fnSettings()._iDisplayLength);
			         
			        if (pageCount > 1)  {
			            paginateRow.css("display", "block");
			        } else {
			            paginateRow.css("display", "none");
			        }
			    }
			});

			$('.dataTable').wrap('<div class="dataTables_scroll" />');
		};

		var selectCols = function(cols) {
			console.log(cols);
			$('.multiselect input').each(function() {
				if($.inArray($(this).val(), cols) >= 0) {
					$(this).attr('checked', true);
				}
				else {
					$(this).attr('checked', false);
				}
			});
		}

		var setUrls = function(arr) {
			urls = arr;
		};

		var minimizeFilter = function() {
			var $el = $('.panel-heading a.adv-crit');
			if(!$el.hasClass('maximize')) {
				$el.click();	
			}
		};

		var initializeWithValues = function(filter_id, query) {
			$("#cdr_template_select").select2('val', filter_id);
			//{"cdr_template":"2","date_range":"2","from_date":"2015-10-13 09:00:00","to_date":"2015-10-13 09:59:59","ingress_carrier_id":"5","egress_carrier_id":"5","ingress_trunk_id":"9","egress_trunk_id":"9","ingress_rate_id":"6","egress_rate_id":"6","ingress_techprefix_id":"","egress_techprefix_id":"","ingress_response_id":"300","egress_response_id":"404","ingress_ani":"ANIPEIR","egress_ani":"DNISIER","ingress_callid":"CallerID","ingress_ringtime_id":"1","ingress_duration_id":"0","sel_cols":["connect_fee","egress_bill_increment","egress_billtime"],"time_zone":"Dublin"}
			if($.trim(query["date_range"]) == '') {
				$('#from_date').val(query["from_date"]);
				$('#to_date').val(query["to_date"]);
			}

			$("#date_range_select").select2('val', query["date_range"], true);

			$("#ingress_carrier_select").select2('val', query["ingress_carrier_id"]);
			$("#egress_carrier_select").select2('val', query["egress_carrier_id"]);
			$("#ingress_trunk_select").select2('val', query["ingress_trunk_id"]);
			$("#egress_trunk_select").select2('val', query["egress_trunk_id"]);
			$("#ingress_rate_select").select2('val', query["ingress_rate_id"]);
			$("#egress_rate_select").select2('val', query["egress_rate_id"]);
			$("#ingress_techprefix_select").select2('val', query["ingress_techprefix_id"]);
			$("#egress_techprefix_select").select2('val', query["egress_techprefix_id"]);
			$("#ingress_response_select").select2('val', query["ingress_response_id"]);
			$("#egress_response_select").select2('val', query["egress_response_id"]);
			$("#ingress_ani").val(query["ingress_ani"]);
			$("#egress_ani").val(query["egress_ani"]);
			$("#ingress_dnis").val(query["ingress_dnis"]);
			$("#egress_dnis").val(query["egress_dnis"]);
			$("#callid").val(query["callid"]);
			$('#ringtime_select').select2('val', query["ringtime_id"]);
			$('#custom_ringtime').val(query["custom_ringtime"]);
			if(query["ringtime_id"] == '-1') {
				$('#custom_rt_field').show();
			}
			$('#duration_select').select2('val', query["duration_id"]);
			$("#tz_select").select2('val', query["time_zone"]);
			$("#sort_by_select").select2('val', query["sort_by"]);

			selectCols(query["sel_cols"]);

			$('#include_all_chk').attr('checked', query["include_all_chk"] == '1');
		};

		return {
			init: init,
			setUrls: setUrls,
			minimizeFilter: minimizeFilter,
			initializeWithValues: initializeWithValues,
			initDatatable: initDatatable,
			selectCols: selectCols

		};
	})(jQuery);

	App.CdrTemplatesHandler = (function($) {
		var urls, destroy_template;

		var init = function() {
			//App.nav.collapseLeftNav();
			$('table#cdr_templates').on('click', '.template-destroy', function() {
				destroy_template = $(this).data('template-id');

				$('.delete-template-confirm-dlg').modal('show');

				return false;
			});

			$('#del_template_confirm_ok').click(function () {
				var link = "a#template_" + destroy_template + "_destroy_link";
				$(link).click();
				
				$('.delete-template-confirm-dlg').modal('hide');
			});

			$('#cdr_templates').dataTable({
				resposive: true,
				"lengthMenu": [ [5, 10, 25, 50, 100, -1], [5, 10, 25, 50, 100, "All"] ],
				"displayLength": 25,
				"columnDefs":[
					{
			    	"targets" : 'no-sort',
			    	"orderable" : false,
			    	}
			    ]
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

	
 App.DidSearchReportHandler = (function($) {
    var urls; 

    var init = function() {
      App.nav.collapseLeftNav();
      
      $(document).on('click', '.adv-crit', function(){
          var t = $(this);
          var p = t.closest('.panel');

          if(!$(this).hasClass('maximize')) {
             p.find('.panel-body').slideUp(200);

             p.find('.adv-crit').each(function() {
                t = jQuery(this);
                t.addClass('maximize');
                if(!t.hasClass('no-text-change')) {
                   t.html('&plus;');
                }   
             });
          } 
          else {
             p.find('.panel-body').slideDown(200);

             p.find('.adv-crit').each(function() {
                t = $(this);
                t.removeClass('maximize');
                if(!t.hasClass('no-text-change')) {
                   t.html('&minus;');
                }
             });
          }
          return false;
        });

        $(document).on('click', '#reports_table th:not(".no-sort"), .paginate_button', function() {
          App.overlayModal.show();
        });

      $('#include_all_chk').change(function() {
        App.overlayModal.show();
        $('#include_all').val($(this).is(':checked') ? 1 : 0);
        $('#include_all_form').submit();
      });

      $(document).on ('click', 'a.export-link', function() {
        var format = $(this).data('format');
        $('input#page_action').val('onscreen');
        $('form#adv_crit_form #format').val(format);
        $("form#adv_crit_form").removeAttr("data-remote");
          $("form#adv_crit_form").removeData("remote").submit();
      });

      $('.submit-btn').click(function() {
        App.overlayModal.show();
        
        $('input#page_action').val($(this).data('action'));
        $('form#adv_crit_form #format').val('js');
        $('form#adv_crit_form').data("remote", true).submit();
      });

      $("#date_range_select").select2({
          width: '100%'
        }).on('change', function() {
        var value = $(this).val();
        var today = moment(new Date());

        switch(value) {
          case '0':
            $('#from_date, #to_date').attr("readonly", true);
            $('#from_date').val(today.format('YYYY-MM-DD 00:00:00'));
            $('#to_date').val(today.format('YYYY-MM-DD 23:59:59'));
          break;
          case '1':
            $('#from_date, #to_date').attr("readonly", true);
            $('#from_date').val(today.format('YYYY-MM-DD HH:00:00'));
            $('#to_date').val(today.format('YYYY-MM-DD HH:59:59'));
          break;
          case '2':
            var last_hour = today.subtract(1, 'h');
            $('#from_date, #to_date').attr("readonly", true);
            $('#from_date').val(last_hour.format('YYYY-MM-DD HH:00:00'));
            $('#to_date').val(last_hour.format('YYYY-MM-DD HH:59:59'));
          break;
          case '3':
            var yesterday = today.subtract(1, 'days');
            $('#from_date, #to_date').attr("readonly", true);
            $('#from_date').val(yesterday.format('YYYY-MM-DD 00:00:00'));
            $('#to_date').val(yesterday.format('YYYY-MM-DD 23:59:59'));
          break;
          case '4':
            $('#from_date, #to_date').attr("readonly", true);
            $('#from_date').val(today.startOf('isoweek').format('YYYY-MM-DD 00:00:00'));
            $('#to_date').val(today.endOf('isoweek').format('YYYY-MM-DD 23:59:59'));
          break;
          case '5':
            var last_week = today.subtract(1, 'weeks');
            $('#from_date, #to_date').attr("readonly", true);
            $('#from_date').val(last_week.startOf('isoweek').format('YYYY-MM-DD 00:00:00'));
            $('#to_date').val(last_week.endOf('isoweek').format('YYYY-MM-DD 23:59:59'));
          break;
          case '6':
            $('#from_date, #to_date').attr("readonly", true);
            $('#from_date').val(today.startOf('month').format('YYYY-MM-DD 00:00:00'));
            $('#to_date').val(today.endOf('month').format('YYYY-MM-DD 23:59:59'));
          break;
          case '7':
            var last_month = today.subtract(1, 'months');
            $('#from_date, #to_date').attr("readonly", true);
            $('#from_date').val(last_month.startOf('month').format('YYYY-MM-DD 00:00:00'));
            $('#to_date').val(last_month.endOf('month').format('YYYY-MM-DD 23:59:59'));
          break;
          case '8':
            $('#from_date, #to_date').attr("readonly", true);
            $('#from_date').val(today.format('YYYY-01-01 00:00:00'));
            $('#to_date').val(today.format('YYYY-12-31 23:59:59'));
          break;
          case '9':
            var last_year = today.subtract(1, 'years');
            $('#from_date, #to_date').attr("readonly", true);
            $('#from_date').val(last_year.format('YYYY-01-01 00:00:00'));
            $('#to_date').val(last_year.format('YYYY-12-31 23:59:59'));
          break;
          default:
            $('#from_date, #to_date').attr("readonly", false);
        }
        });
      
        $("#tz_select").select2({
          width: '100%'
        });

     

      $("#ingress_carrier_select").select2({
          width: '90%'
        }).change(function() {
          var value = $(this).val();
          data = {
              carrier_id: value, 
              include_all: $('#include_all').is(':checked') ? 1 : 0
          };
          $.get('/reports/ingress_pin_down', data, null, 'script');
        });

        $('#sel_all_cols').click(function() {
          $('.display-col').attr('checked', true);
        });

        $('#remove_all_cols').click(function() {
          $('.display-col').attr('checked', false);
        });

        $('#invert_cols').click(function() {
          var unchecked = $('.display-col').not(":checked");
          $('.display-col:checked').attr('checked', false);
          unchecked.attr('checked', true);
        });
        //$(".multiselect").multiselect();

        $('#duration_select').select2({
          width: '90%'
        });
        
        $('#sort_by_select').select2({
          width: '100%',
          placeholder: 'Please Select'
        });

        $('#from_date').datetimepicker({
          format: 'YYYY-MM-DD HH:mm:ss'
        });

        $('#to_date').datetimepicker({
          format: 'YYYY-MM-DD HH:mm:ss',
          useCurrent: false
        });

        $("#from_date").on("dp.change", function (e) {
          var to_date = $('#to_date').val();
          var from_date = $('#from_date').val();

          if(e.date == null) {
            $('#from_date').val($('#to_date').val());
          }
          else {
            if(moment(from_date).isAfter(to_date)) {
              $('#to_date').val($('#from_date').val());
            }
            
            $('#to_date').data("DateTimePicker").minDate(e.date); 
            
            
          }
          });

          $("#to_date").on("dp.change", function (e) {
            var to_date = $('#to_date').val();
            var from_date = $('#from_date').val();
            
              if(e.date == null) {
              $('#to_date').val($('#from_date').val());
            }
            else {
              if(moment(to_date).isBefore(from_date)) {
                $('#from_date').val($('#to_date').val());
              }

              $('#from_date').data("DateTimePicker").maxDate(e.date);
            }
         });
    };

    var initDatatable = function(selector, total_records) {
      $(selector).dataTable({
        resposive: true,
        "sDom": '<"top"l>rt<"bottom"ip><"clear">',
        "lengthMenu": [ [25, 50, 100, 200], [25, 50, 100, 200] ],
        "displayLength": 25,
        "columnDefs":[{
            "targets" : 'no-sort',
            "orderable" : false,
          }],
          "order": [],
          "processing": true,
          "serverSide": true,
          "deferLoading": total_records,
          "ajax": {
            url: urls[2],
            method: 'post',
            data: {
              page: function() {
                return $('#reports_table').DataTable().page.info().page + 1;
              }
            } 
          },
          "language": {
          "paginate": {
            "previous": "<<",
            "next": ">>"
              },
              "search": ""
          },
          "fnDrawCallback": function() {
            App.overlayModal.hide();
              var paginateRow = $(this).parent().children('div.dataTables_paginate');
              var pageCount = Math.ceil((this.fnSettings().fnRecordsDisplay()) / this.fnSettings()._iDisplayLength);
               
              if (pageCount > 1)  {
                  paginateRow.css("display", "block");
              } else {
                  paginateRow.css("display", "none");
              }
          }
      });

      $('.dataTable').wrap('<div class="dataTables_scroll" />');
    };

    var selectCols = function(cols) {
      console.log(cols);
      $('.multiselect input').each(function() {
        if($.inArray($(this).val(), cols) >= 0) {
          $(this).attr('checked', true);
        }
        else {
          $(this).attr('checked', false);
        }
      });
    }

    var setUrls = function(arr) {
      urls = arr;
    };

    var minimizeFilter = function() {
      var $el = $('.panel-heading a.adv-crit');
      if(!$el.hasClass('maximize')) {
        $el.click();  
      }
    };

    var initializeWithValues = function(filter_id, query) {
     if($.trim(query["date_range"]) == '') {
        $('#from_date').val(query["from_date"]);
        $('#to_date').val(query["to_date"]);
      }

      $("#date_range_select").select2('val', query["date_range"], true);
      $("#ingress_carrier_select").select2('val', query["ingress_carrier_id"]);
      $('#duration_select').select2('val', query["duration_id"]);
      $("#tz_select").select2('val', query["time_zone"]);
      $("#sort_by_select").select2('val', query["sort_by"]);

      selectCols(query["sel_cols"]);

      $('#include_all_chk').attr('checked', query["include_all_chk"] == '1');
    };

    return {
      init: init,
      setUrls: setUrls,
      minimizeFilter: minimizeFilter,
      initializeWithValues: initializeWithValues,
      initDatatable: initDatatable,
      selectCols: selectCols

    };
  })(jQuery);
	
	
	App.CdrLogsHandler = (function($) {
		var urls, refreshTimeout = null;
        var isAdmin;

		var init = function(isAdminParam, refresh) {
            isAdmin = isAdminParam;
			App.nav.collapseLeftNav();
            		   	
		   	$(document).on('click', '#reports_table th:not(".no-sort"), .paginate_button', function() {
		   		App.overlayModal.show();
		   	});

			$('.submit-btn').click(function() {
				App.overlayModal.show();
				$('form#adv_crit_form #format').val('js');
				$('form#adv_crit_form').data("remote", true).submit();
			});

			$("#date_range_select").select2({
  				width: '100%'
  			}).on('change', function() {
				var value = $(this).val();
				var today = moment(new Date());

				switch(value) {
					case '0':
						$('#from_date, #to_date').attr("readonly", true);
						$('#from_date').val(today.format('YYYY-MM-DD 00:00:00'));
						$('#to_date').val(today.format('YYYY-MM-DD 23:59:59'));
					break;
					case '1':
						$('#from_date, #to_date').attr("readonly", true);
						$('#from_date').val(today.format('YYYY-MM-DD HH:00:00'));
						$('#to_date').val(today.format('YYYY-MM-DD HH:59:59'));
					break;
					case '2':
						var last_hour = today.subtract(1, 'h');
						$('#from_date, #to_date').attr("readonly", true);
						$('#from_date').val(last_hour.format('YYYY-MM-DD HH:00:00'));
						$('#to_date').val(last_hour.format('YYYY-MM-DD HH:59:59'));
					break;
					case '3':
						var yesterday = today.subtract(1, 'days');
						$('#from_date, #to_date').attr("readonly", true);
						$('#from_date').val(yesterday.format('YYYY-MM-DD 00:00:00'));
						$('#to_date').val(yesterday.format('YYYY-MM-DD 23:59:59'));
					break;
					case '4':
						$('#from_date, #to_date').attr("readonly", true);
						$('#from_date').val(today.startOf('isoweek').format('YYYY-MM-DD 00:00:00'));
						$('#to_date').val(today.endOf('isoweek').format('YYYY-MM-DD 23:59:59'));
					break;
					case '5':
						var last_week = today.subtract(1, 'weeks');
						$('#from_date, #to_date').attr("readonly", true);
						$('#from_date').val(last_week.startOf('isoweek').format('YYYY-MM-DD 00:00:00'));
						$('#to_date').val(last_week.endOf('isoweek').format('YYYY-MM-DD 23:59:59'));
					break;
					case '6':
						$('#from_date, #to_date').attr("readonly", true);
						$('#from_date').val(today.startOf('month').format('YYYY-MM-DD 00:00:00'));
						$('#to_date').val(today.endOf('month').format('YYYY-MM-DD 23:59:59'));
					break;
					case '7':
						var last_month = today.subtract(1, 'months');
						$('#from_date, #to_date').attr("readonly", true);
						$('#from_date').val(last_month.startOf('month').format('YYYY-MM-DD 00:00:00'));
						$('#to_date').val(last_month.endOf('month').format('YYYY-MM-DD 23:59:59'));
					break;
					case '8':
						$('#from_date, #to_date').attr("readonly", true);
						$('#from_date').val(today.format('YYYY-01-01 00:00:00'));
						$('#to_date').val(today.format('YYYY-12-31 23:59:59'));
					break;
					case '9':
						var last_year = today.subtract(1, 'years');
						$('#from_date, #to_date').attr("readonly", true);
						$('#from_date').val(last_year.format('YYYY-01-01 00:00:00'));
						$('#to_date').val(last_year.format('YYYY-12-31 23:59:59'));
					break;
					default:
						$('#from_date, #to_date').attr("readonly", false);
				}
  			});
			
  			$('#from_date').datetimepicker({
  				format: 'YYYY-MM-DD HH:mm:ss'
  			});

  			$('#to_date').datetimepicker({
  				format: 'YYYY-MM-DD HH:mm:ss',
  				useCurrent: false
  			});

  			$("#from_date").on("dp.change", function (e) {
  				var to_date = $('#to_date').val();
  				var from_date = $('#from_date').val();

  				if(e.date == null) {
  					$('#from_date').val($('#to_date').val());
  				}
  				else {
  					if(moment(from_date).isAfter(to_date)) {
  						$('#to_date').val($('#from_date').val());
  					}
  					
  					$('#to_date').data("DateTimePicker").minDate(e.date);
  				}
	       	});

	       	$("#to_date").on("dp.change", function (e) {
	       		var to_date = $('#to_date').val();
    				var from_date = $('#from_date').val();
    				
  	       		if(e.date == null) {
					$('#to_date').val($('#from_date').val());
				}
				else {
					if(moment(to_date).isBefore(from_date)) {
						$('#from_date').val($('#to_date').val());
					}

					$('#from_date').data("DateTimePicker").maxDate(e.date);
				}
	        });

            if(isAdmin) {
                $('#username_select').select2({
                    width: '100%',
                    minimumInputLength: 4,
                    allowClear: true,
                    placeholder: 'Created By User',
                    ajax: {
                        url: '/reports/username_search',
                        dataType: 'json',
                        quietMillis: 250,
                        data: function(term, page) {
                            return {
                                q: term
                            }
                        },
                        results: function(data) {
                            return {
                                results: $.map(data, function (item) {
                                return {
                                        text: item.username + " (" + item.name + ")",
                                        //slug: item.slug,
                                        id: item.username
                                    }
                                })
                            }
                        }
                    }
                });
            }

            $('#from_date, #to_date').attr("readonly", true);

            if(refresh) {
            	$('.submit-btn').click();
            }
		};

		var initDatatable = function(selector, total_records) {
            var coldefs;

            if(isAdmin) {
                coldefs = [
                    {
                        "targets" : 'no-sort',
                        "orderable" : false,
                    },
                    {
                        "targets": 5,
                        "createdCell": function(td, cellData, rowData, row, col) {
                            //refresh after 5 minutes
                            if(cellData.toLowerCase() == 'started' && !refreshTimeout) {
                                refreshTimeout = setTimeout(function() {
                                    refreshTimeout = null;
                                    $('form#adv_crit_form').data("remote", true).submit();
                                }, 300000)
                            }
                        }
                    },
                    {
                        "targets": 7,
                        "createdCell": function(td, cellData, rowData, row, col) {
                            var link = '--'
                            if(rowData[5].toLowerCase() == 'done') {
                                link = '<a class="btn btn-primary btn-sm" href="'+ cellData +'" target="_blank">Download</a>';
                            }
                            
                            $(td).addClass('text-center').html(link);
                        }
                    }
                ]
            }
            else {
                coldefs = [
                    {
                        "targets" : 'no-sort',
                        "orderable" : false,
                    },
                    {
                        "targets": 4,
                        "createdCell": function(td, cellData, rowData, row, col) {
                            //refresh after 5 minutes
                            if(cellData.toLowerCase() == 'started' && !refreshTimeout) {
                                refreshTimeout = setTimeout(function() {
                                    refreshTimeout = null;
                                    $('form#adv_crit_form').data("remote", true).submit();
                                }, 300000)
                            }
                        }
                    },
                    {
                        "targets": 6,
                        "createdCell": function(td, cellData, rowData, row, col) {
                            var link = '--'
                            if(rowData[4].toLowerCase() == 'done') {
                                link = '<a class="btn btn-primary btn-sm" href="'+ cellData +'" target="_blank">Download</a>';
                            }
                            
                            $(td).addClass('text-center').html(link);
                        }
                    }
                ]
            }

			$(selector).dataTable({
				resposive: true,
				"sDom": '<"top"l>rt<"bottom"ip><"clear">',
				"lengthMenu": [ [25, 50, 100, 200], [25, 50, 100, 200] ],
				"displayLength": 25,
				"columnDefs": coldefs,
			    "processing": true,
			    "serverSide": true,
			    "deferLoading": total_records,
			    "ajax": {
			    	url: urls[1],
			    	method: 'post',
			    	data: {
			    		page: function() {
			    			return $('#reports_table').DataTable().page.info().page + 1;
			    		}
			    	}	
			    },
			    "language": {
					"paginate": {
						"previous": "<<",
						"next": ">>"
			        },
			        "search": ""
			    },
			    "fnDrawCallback": function() {
			    	App.overlayModal.hide();
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

		var minimizeFilter = function() {
			var $el = $('.panel-heading a.adv-crit');
			if(!$el.hasClass('maximize')) {
				$el.click();	
			}
		};

		var initializeWithValues = function(filter_id, query) {
			
			if($.trim(query["date_range"]) == '') {
				$('#from_date').val(query["from_date"]);
				$('#to_date').val(query["to_date"]);
			}

			$("#date_range_select").select2('val', query["date_range"], true);
		};

		return {
			init: init,
			setUrls: setUrls,
			minimizeFilter: minimizeFilter,
			initializeWithValues: initializeWithValues,
			initDatatable: initDatatable
		};
	})(jQuery);
	
	App.SMSReportHandler = (function($) {
	    var urls; 

	    var init = function() {
	      App.nav.collapseLeftNav();

	      $(document).on('click', '.adv-sms', function(){
	          var t = $(this);
	          var p = t.closest('.panel');
	          if(!$(this).hasClass('maximize')) {
	             p.find('.panel-body').slideUp(200);

	             p.find('.adv-sms').each(function() {
	                t = jQuery(this);
	                t.addClass('maximize');
	                if(!t.hasClass('no-text-change')) {
	                   t.html('&plus;');
	                }   
	             });
	          } 
	          else {
	             p.find('.panel-body').slideDown(200);

	             p.find('.adv-sms').each(function() {
	                t = $(this);
	                t.removeClass('maximize');
	                if(!t.hasClass('no-text-change')) {
	                   t.html('&minus;');
	                }
	             });
	          }
	          return false;
	       });

	      $('#include_all_chk').change(function() {
	        App.overlayModal.show();
	        $('#include_all').val($(this).is(':checked') ? 1 : 0);    
	        $('#include_all_form').submit();
	      });

	      $(document).on ('click', 'a.export-link', function() {
	        var format = $(this).data('format');
	        $('form#adv_sms_form #format').val(format);
	        $("form#adv_sms_form").removeAttr("data-remote");
	        $("form#adv_sms_form").removeData("remote").submit();
	      });

	      $('.submit-btn').click(function() {
	        App.overlayModal.show();
	        $('form#adv_sms_form #format').val('js');
	        $('form#adv_sms_form').data("remote", true).submit();
	      });

	      $("#date_range_select").select2({
	          width: '100%'
	        }).on('change', function() {
	        var value = $(this).val();
	        var today = moment(new Date());

	        switch(value) {
	          case '0':
	            $('#from_date, #to_date').attr("readonly", true);
	            $('#from_date').val(today.format('YYYY-MM-DD 00:00:00'));
	            $('#to_date').val(today.format('YYYY-MM-DD 23:59:59'));
	          break;
	          case '1':
	            $('#from_date, #to_date').attr("readonly", true);
	            $('#from_date').val(today.format('YYYY-MM-DD HH:00:00'));
	            $('#to_date').val(today.format('YYYY-MM-DD HH:59:59'));
	          break;
	          case '2':
	            var last_hour = today.subtract(1, 'h');
	            $('#from_date, #to_date').attr("readonly", true);
	            $('#from_date').val(last_hour.format('YYYY-MM-DD HH:00:00'));
	            $('#to_date').val(last_hour.format('YYYY-MM-DD HH:59:59'));
	          break;
	          case '3':
	            var yesterday = today.subtract(1, 'days');
	            $('#from_date, #to_date').attr("readonly", true);
	            $('#from_date').val(yesterday.format('YYYY-MM-DD 00:00:00'));
	            $('#to_date').val(yesterday.format('YYYY-MM-DD 23:59:59'));
	          break;
	          case '4':
	            $('#from_date, #to_date').attr("readonly", true);
	            $('#from_date').val(today.startOf('isoweek').format('YYYY-MM-DD 00:00:00'));
	            $('#to_date').val(today.endOf('isoweek').format('YYYY-MM-DD 23:59:59'));
	          break;
	          case '5':
	            var last_week = today.subtract(1, 'weeks');
	            $('#from_date, #to_date').attr("readonly", true);
	            $('#from_date').val(last_week.startOf('isoweek').format('YYYY-MM-DD 00:00:00'));
	            $('#to_date').val(last_week.endOf('isoweek').format('YYYY-MM-DD 23:59:59'));
	          break;
	          case '6':
	            $('#from_date, #to_date').attr("readonly", true);
	            $('#from_date').val(today.startOf('month').format('YYYY-MM-DD 00:00:00'));
	            $('#to_date').val(today.endOf('month').format('YYYY-MM-DD 23:59:59'));
	          break;
	          case '7':
	            var last_month = today.subtract(1, 'months');
	            $('#from_date, #to_date').attr("readonly", true);
	            $('#from_date').val(last_month.startOf('month').format('YYYY-MM-DD 00:00:00'));
	            $('#to_date').val(last_month.endOf('month').format('YYYY-MM-DD 23:59:59'));
	          break;
	          case '8':
	            $('#from_date, #to_date').attr("readonly", true);
	            $('#from_date').val(today.format('YYYY-01-01 00:00:00'));
	            $('#to_date').val(today.format('YYYY-12-31 23:59:59'));
	          break;
	          case '9':
	            var last_year = today.subtract(1, 'years');
	            $('#from_date, #to_date').attr("readonly", true);
	            $('#from_date').val(last_year.format('YYYY-01-01 00:00:00'));
	            $('#to_date').val(last_year.format('YYYY-12-31 23:59:59'));
	          break;
	          default:
	            $('#from_date, #to_date').attr("readonly", false);
	        }
	        });

	        $("#tz_select").select2({
	          width: '100%'
	        });

	        $("#sms_carrier_select").select2({
	          width: '75%'
	        });
	        
	        $("#group_option_select").select2({
	          width: '75%'
	        }).on("select2-open", function(e) {
	           $('ul.select2-results').css('max-height', '275px');
	        });

	        $('#from_date').datetimepicker({
	          format: 'YYYY-MM-DD HH:mm:ss'
	        });

	        $('#to_date').datetimepicker({
	          format: 'YYYY-MM-DD HH:mm:ss',
	          useCurrent: false
	        });

	        $("#from_date").on("dp.change", function (e) {
	          var to_date = $('#to_date').val();
	          var from_date = $('#from_date').val();

	          if(e.date == null) {
	            $('#from_date').val($('#to_date').val());
	          }
	          else {
	            if(moment(from_date).isAfter(to_date)) {
	              $('#to_date').val($('#from_date').val());
	            }
	            
	            $('#to_date').data("DateTimePicker").minDate(e.date); 
	          }
	          });

	          $("#to_date").on("dp.change", function (e) {
	            var to_date = $('#to_date').val();
	            var from_date = $('#from_date').val();
	            
	              if(e.date == null) {
	          $('#to_date').val($('#from_date').val());
	        }
	        else {
	          if(moment(to_date).isBefore(from_date)) {
	            $('#from_date').val($('#to_date').val());
	          }

	          $('#from_date').data("DateTimePicker").maxDate(e.date);
	        }
	         });
	    };

	    var setUrls = function(arr) {
	      urls = arr;
	    };

	    var minimizeFilter = function() {
	      var $el = $('.panel-heading a.adv-sms');
	      if(!$el.hasClass('maximize')) {
	        $el.click();  
	      }
	    };

	    var initDatatable = function(selector) {
	      $(selector).dataTable({
	        resposive: true,
	        "lengthMenu": [ [10, 25, 50, 100, -1], [10, 25, 50, 100, "All"] ],
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
	          }
	      });
    	};

		return {
	      init: init,
	      setUrls: setUrls,
	      minimizeFilter: minimizeFilter,
	      initDatatable: initDatatable
	    };
  	})(jQuery);
});

