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
//= require_self

var App = App || {};
var destroy_grp = null;

jQuery(document).ready(function() {
	App.CarrierManageDids = (function($) {
		var urls;

		var init = function() {
			initMoveToSelect2();
			initGroupDatatable('.did_group');
			initEditDidDescription();
			//initEditDidGrpDescription('.did-group-desc');
			initDTSearch();

			$('#did_groups_container').on('click', '.group_destroy', function() {
				var group_id = $(this).data('group-id');
				if($('table#group_'+ group_id +'_table tbody tr[role="row"]').length > 0) {
					$('.delete-group-unempty-dlg').modal('show');
				}
				else {
					destroy_grp = group_id;
					$('.delete-group-confirm-dlg').modal('show');
				}

				return false;
			});

			$('#del_grp_confirm_ok').click(function () {
				var link = "a#group_" + destroy_grp + "_destroy_link";
				$(link).click();
				$('.delete-group-confirm-dlg').modal('hide');
			});

			$.validator.addMethod("alphaOnly", function(value, element) {
				return this.optional(element) || App.alphaOnlyRegex.test(value);
			}, "Group name must contain only letters, numbers, or dashes.");

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
					"did_group[name]" : {
						required : true,
						minlength: 3,
						maxlength: 254,
						alphaOnly: true,
						remote : {
							url : "/inbound_dids_groups/check_group_name",
							type : "get"
						}
					},
					"did_group[description]": {
						required: false,
						minlength: 3
					}
				},
				messages : {
					"did_group[description]": "Enter few more words ...",
					"did_group[name]": {
						remote: "This group name already exists. "
					}
				}
			}; 
			$create_group_form = $('#create_group_form').validate(validationOptions);
			
			$(document).on('click', 'a.close_modal', function() {
				$(this).parents('.modal').modal('hide');					
			});

			$('div.edit-group-dlg').on('click', 'a.close_modal', function() {
				$(this).parents('.modal').modal('hide');
			})
			.on('show.bs.modal', function(e) {
				var url = $(e.relatedTarget).data('url');
				$.get(url, function(data) {
					$(".edit-group-dlg .modal-content").html(data);
				});
			});

			$('.create-group-dlg').on('show.bs.modal', function() {
				 $('form#create_group_form')[0].reset();		
			});

			$("div.checkbox_toggler_container").on('click', '.result_select_all', function() {
				$("div#did_groups_container input.did-cb:checkbox:not(:checked)").attr('checked', true);	
				$("div#did_groups_container input.table-cb-toggler:not(:checked)").attr('checked', true);
			 	toggleGroupButtons();
			});
			
			$("div.checkbox_toggler_container").on('click', '.result_deselect_all', function() {
				$("div#did_groups_container input.did-cb:checkbox:checked").attr('checked', false);
				$("div#did_groups_container input.table-cb-toggler").attr('checked', false);
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

			$("div#did_groups_container").on('click', 'input.table-cb-toggler', function() {
				var el = $(this);
				var table_id = el.data('table');
				if(el.is(":checked")) {
					$("div#did_groups_container " + table_id + " input.did-cb:checkbox").attr('checked', true);
				}
				else {
					$("div#did_groups_container " + table_id + " input.did-cb:checkbox").attr('checked', false);
				}				

			 	toggleGroupButtons();
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
				 var form = $('form#selected_dids_form');	
				 $(this).find('form')[0].reset();
				 $('#rel_did_confirm_ok').addClass('disabled');
				 $('input#release_reason').val('');
				 $('#release_other_reason').hide();
				 form.attr('action', urls[1]);
			});

			$('#rel_did_confirm_ok').click(function() {
				if('' == $.trim($('input#release_reason').val())) {
					return;
				}
				
				if($('#single_did').val() != '' || $("div#did_groups_container input.did-cb:checkbox:checked").length > 0) {
					$('form#selected_dids_form').submit();	
				}
			});


			$('#did_groups_container').on('click', '.release-link', function() {
				var id = $(this).data('pk');
				$('#single_did').val(id);
			});

			$('input#global_search_q').on('keyup click', function() {
        		$('.did_group').DataTable().search($(this).val(), true, true).draw();
    		});

			//Show-Hide all groups
    		$('a.show-hide-all').click(function() {
    			var icon = $(this).find('span');
    			if(icon.hasClass('glyphicon-minus')){
    				icon.removeClass('glyphicon-minus').addClass('glyphicon-plus');
    				$('div.group-container a.minimize').removeClass('maximize').click();
    			}
    			else {
    				icon.removeClass('glyphicon-plus').addClass('glyphicon-minus');	
    				$('div.group-container a.minimize').addClass('maximize').click();
    			}
    		});
		};

		var initDTSearch = function() {
			$('.group-container input[type="search"]').attr('placeholder', 'Search group...')
		};

		var toggleGroupButtons = function() {
			if ($("div#did_groups_container input.did-cb:checkbox:checked").length > 0) {
				$('#btn_release_all, #btn_bulk_sms_settings, #btn_bulk_voice_settings').removeClass('disabled');	
			}			
			else {
				$('#btn_release_all, #btn_bulk_sms_settings, #btn_bulk_voice_settings').addClass('disabled');
			}
		};

		var initMoveToSelect2 = function() {
			$(".moveto-select2").select2({width: '75%'})
			.on('change', function(e) {
				if($("div#did_groups_container input.did-cb:checkbox:checked").length < 1) {
					return;
				};

				$("input#move_to").val(e.val);
				$("form#selected_dids_form").attr("action", urls[0]).submit();
			});
		};

		var addNewGroupOption = function(id, name) {
			$('<option value="'+ id +'">'+ name +'</option>').appendTo('#did_groups_select');
		};

		var updateGroupOption = function(id, name) {
			$("#did_groups_select option[value='"+ id +"']").html(name);
		};

		var initGroupDatatable = function(selector) {
			$(selector).dataTable({
				resposive: true,
				"lengthMenu": [ [5, 10, 25, 50, 100, -1], [5, 10, 25, 50, 100, "All"] ],
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

		var initEditDidDescription = function() {
			$('#did_groups_container').editable({
				toggle: 'click',
				selector: '.did-desc',
				validate: function(value) {
					if($.trim(value) === '')
						return 'Enter few words for description or cancel';
				},
				url: urls[2],
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

		var initEditDidGrpDescription = function(selector) {
			$(selector).editable({
				toggle: 'click',
				validate: function(value) {
					if($.trim(value) === '')
						return 'Enter few words for description or cancel';
				},
				url: '/inbound_dids_groups/update_didgrp_desc',
        		title: 'Update description',
        		rows: 5,
        		ajaxOptions: {
        			type: 'put'
        		}
			});
		};

		var removeGroup = function(group_id) {
			var $targetCont = $('div#group_'+ group_id +'_container');
			$targetCont.hide('slow', function(){ $targetCont.remove(); });
			$('select#did_groups_select option[value="'+ group_id +'"]').remove();
		};

		var updateGroup = function(id, name, description) {
			$("#group_"+ id +"_name").html(name + " DIDs");
			$("#group_" + id + "_desc").html(description);
		};

		var initEditGroupForm = function(name) {
			new_rules = {rules : {
					"did_group[name]" : {
						required : true,
						minlength: 3,
						maxlength: 254,
						remote : {
							url : "/inbound_dids_groups/check_group_name",
							data: {ignore: name},
							type : "get"
						}
					},
					"did_group[description]": {
						required: false,
						minlength: 3
					}
				}};
			$('#edit_group_form').validate($.extend(true, new_rules, validationOptions));				
		};

		var setUrls = function(arr) {
			urls = arr;
		};
		
		return {
			init: init,
			initGroupDatatable: initGroupDatatable,
			initEditDidDescription: initEditDidDescription,
			initEditDidGrpDescription: initEditDidGrpDescription,
			initDTSearch:  initDTSearch,
			addNewGroupOption: addNewGroupOption,
			updateGroupOption: updateGroupOption,
			removeGroup: removeGroup,
			updateGroup: updateGroup,
			initEditGroupForm: initEditGroupForm,
			setUrls: setUrls
		};
	})(jQuery);		
});
