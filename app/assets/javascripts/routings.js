//= require bootstrap.min
//= require modernizr.min
//= require toggles.min
//= require retina.min
//= require jquery.cookies
//= require jquery.validate.min
//= require select2.min
//= require jquery.datatables.min
//= require jquery.gritter.min
//= require custom
//= require_self

var App = App || {};

jQuery(document).ready(function() {
	App.RoutingPlanFormHandler = (function($) {
		var urls;

		var init = function() {
			$(".egress-trunks-select").select2({
				width: '100%',
				formatSelection: function(object, container) {
					label = object.element[0].parentElement.label;
					//label = $(object.element).parent('optgroup')[0].label;
					return label.truncate(30) + ' - ' + object.text;
				}
			});

			$(".select2").select2({
				width: '100%',
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
					"routing[name]" : {
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
					"routing[name]" : {
						remote : "This routing plan name already exists with us."
					}
				}
			};

			$editFormValidator = $('#editRoutingPlanForm').validate($.extend(true, {}, validationOptions, {
				rules: {
					"routing[name]": {remote: {
						data: {id: $('#routing_id').val()}
					}}
				}
			}));
			
			$newFormValidator = $('#newRoutingPlanForm').validate($.extend(true, {}, validationOptions, {}));
		};

		var setUrls = function(arr) {
			urls = arr;
		};

		return {
			init: init,
			setUrls: setUrls
		}
	})(jQuery);

	App.RoutingListHandler = (function($) {
		var urls, destroy_routing = null, remove_trunk, enable_trunk, 
			disable_trunk, routing_plan, timer;

		var init = function() {
			$(document).on('click', 'a.close_modal', function() {
				$(this).parents('.modal').modal('hide');					
			});

			$('#routing_plans_container').on('click', '.routing-destroy', function() {
				var routing_id = $(this).data('routing-id');
				
				destroy_routing = routing_id;
				$('.delete-routing-confirm-dlg').modal('show');

				return false;
			});

			$('#del_routing_confirm_ok').click(function () {
				var link = "a#routing_" + destroy_routing + "_destroy_link";
				$(link).click();
				$('.delete-routing-confirm-dlg').modal('hide');
			});

			//Show-Hide all routing plan
    		$('a.show-hide-all').click(function() {
    			var icon = $(this).find('span');
    			if(icon.hasClass('glyphicon-minus')){
    				icon.removeClass('glyphicon-minus').addClass('glyphicon-plus');
    				$('div.routing-plan-container a.minimize').addClass('maximize').click();
    			}
    			else {
    				icon.removeClass('glyphicon-plus').addClass('glyphicon-minus');	
    				$('div.routing-plan-container a.minimize').removeClass('maximize').click();
    			}
    		});

    		$('#routings_container').on('click', '.trunk_disable', function() {
				disable_trunk = $(this).data('trunk-id');
				routing_plan = $(this).data('routing-id');

				$('.disable-trunk-confirm-dlg').modal('show');

				return false;
			});

			$('#disable_trunk_confirm_ok').click(function () {
				
				var link = "a#routing_"+ routing_plan + "_trunk_" + disable_trunk + "_disable_link";
				$(link).click();
				
				$('.disable-trunk-confirm-dlg').modal('hide');
			});

			$('#routings_container').on('click', '.trunk_enable', function() {
				enable_trunk = $(this).data('trunk-id');
				routing_plan = $(this).data('routing-id');
				
				$('.enable-trunk-confirm-dlg').modal('show');

				return false;
			});

			$('#enable_trunk_confirm_ok').click(function () {
				var link = "a#routing_"+ routing_plan + "_trunk_" + enable_trunk + "_enable_link";
				$(link).click();
				$('.enable-trunk-confirm-dlg').modal('hide');
			});

			$('#routings_container').on('click', '.trunk_remove', function() {
				remove_trunk = $(this).data('trunk-id');
				routing_plan = $(this).data('routing-id');

				$('.remove-trunk-confirm-dlg').modal('show');

				return false;
			});

			$('#rem_trunk_confirm_ok').click(function () {
				var link = "a#routing_"+ routing_plan +"_trunk_" + remove_trunk + "_remove_link";
				$(link).click();
				$('.remove-trunk-confirm-dlg').modal('hide');
			});

			$('#global_search_q').keyup(function(e) {
  				var val = $(this).val();

  				if(timer) {
  					clearTimeout(timer);
  				}
				
				timer = setTimeout(globalSearch, 400, val);
  			});
		};

		var globalSearch = function(val) {
			$.get(urls[0], {q: val}, null, 'script');	
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