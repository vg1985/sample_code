//= require bootstrap.min
//= require modernizr.min
//= require toggles.min
//= require retina.min
//= require jquery.cookies
//= require bootstrap-wizard.min
//= require jquery.validate.min
//= require select2.min
//= require jquery.datatables.min
//= require jquery.gritter.min
//= require custom
//= require_self

var App = App || {};

jQuery(document).ready(function() {
	App.UserFormHandler = (function($) {
		var urls;

		var init = function() {
			$(".select2").select2({
				width: '100%',
			});

			$('#cancelForm').click(function(e) {
				e.preventDefault();
				document.location.href="/users";
			});

			$.validator.addMethod("passwordRules", function(value, element) {
				return this.optional(element) || /\d+/.test(value);
			}, "Password must contain atleast one number.");

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
					"user[name]" : {
						required : true,
						minlength: 2,
						maxlength: 25,
					},
					"user[username]" : {
						required : true,
						minlength: 3,
						maxlength: 25,
						remote : {
							url : urls[0],
							type : "get",
							data : {
								user_id: function() {
									return $("#user_id").val();
								}
							}
						}
					},
					"user[email]" : {
						required : true,
						email : true,
						minlength : 5,
						maxlength : 255,
						remote : {
							url : urls[1],
							type : "get",
							data : {
								user_id: function() {
									return $("#user_id").val();
								}
							}
						}
					},
					"user[password]" : {
						minlength : 5,
						maxlength : 15,
						passwordRules: true
					},
					"user[password_confirmation]" : {
						equalTo : "#user_password"
					},
					"user[role_ids][]" : {
						required : true,
					},
					/*
					"user[address1]" : {
						required : true,
						minlength : 1,
						maxlength : 50
					},
					
					"user[city]" : {
						required : true,
						minlength : 2,
						maxlength : 25
					},
					
					"user[state]" : {
						required : true
					},
					
					"user[country]" : {
						required : true
					},
					
					"user[timezone]" : {
						required : true
					},
					
					"user[phone1]" : {
						required: true,
						minlength: 6,
						digits : true
					},
					"user[zip]" : {
						required: true,
						minlength: 6,
						digits : true
					},
					"user[phone2]" : {
						digits : true
					},
					"user[mobile]" : {
						required: true,
						minlength: 10,
						digits : true
					}
					*/
				},
				messages : {
					"user[username]" : {
						remote : "This Username already exists with us."
					},
					"user[email]" : {
						remote : "This Email already exists with us."
					}
				}
			};
			
			$editFormValidator = $('#editUserForm').validate($.extend(true, {}, validationOptions));
			$newFormValidator = $('#newUserForm').validate($.extend(true, {}, validationOptions, {
				rules: {
					"user[password]": { required: true },
					"user[email]": {remote: {
						data: {user_id: -1}
					}},
					"user[username]": {remote: {
						data: {user_id: -1}
					}}
				}
			}));

			//init bootstrap wizard
			$('#editUserWizard').bootstrapWizard({
				'nextSelector' : '.next',
				'previousSelector' : '.previous',
				onNext : function(tab, navigation, index) {
					return validateEditForm();
				},
				onPrevious : function(tab, navigation, index) {
					return validateEditForm();
				},
				onTabClick: function(tab, navigation, index) {
					return validateEditForm();
				}
			});

			$('#newUserWizard').bootstrapWizard({
				'nextSelector' : '.next',
				'previousSelector' : '.previous',
				onNext : function(tab, navigation, index) {
					var total, current, percent;
					
					$('#newFormFinishBtn').addClass('disabled');
					
					if(validateNewForm()) {
						/*total = navigation.find('li').length;
						current = index + 1;
						percent = (current / total) * 100;
						
						$('#newCarrierWizard').find('.progress-bar').css('width', percent + '%');
						*/
						if (index == 1) {
							$('#newFormFinishBtn').removeClass('disabled');
						}
						
						return true;
					}
					
					return false;
				},
				onPrevious : function(tab, navigation, index) {
					var total, current, percent;
					
					$('#newFormFinishBtn').addClass('disabled');
					
					if(validateNewForm()) {
						/*
						total = navigation.find('li').length;
						current = index + 1;
						percent = (current / total) * 100;
						
						$('#newCarrierWizard').find('.progress-bar').css('width', percent + '%');
						*/
						return true;
					}
					
					return false;
				},
				onTabShow: function(tab, navigation, index) {
					return;
					/*
					var total, current, percent;
					
					total = navigation.find('li').length;
					current = index + 1;
					percent = (current / total) * 100;
					
					$('#newCarrierWizard').find('.progress-bar').css('width', percent + '%');
					*/
				},
				onTabClick: function(tab, navigation, index) {
					return false;
    			}
			});

		};

		var validateNewForm = function() {	
			var $valid = $('#newUserForm').valid();
				
			if (!$valid) {
				console.log('Invalid...');
				$newFormValidator.focusInvalid();
				return false;
			}
			
			return true;
		};

		var validateEditForm = function() {
			var $valid = $('#editUserForm').valid();
					
			if (!$valid) {
				$editFormValidator.focusInvalid();
				return false;
			}
			
			return true;
		};

		var setUrls = function(arr) {
			urls = arr;
		};

		return {
			init: init,
			setUrls: setUrls
		};
	})(jQuery);
	
	
	App.UserListHandler = (function($) {
		var urls, destroy_user, disable_user, enable_user,
			bulk_operation = false; 

		var init = function(toggleStatuses) {
			$(document).on('click', 'a.close_modal', function() {
				$(this).parents('.modal').modal('hide');					
				bulk_operation = false;
			});

			$("div.checkbox_toggler_container").on('click', '.result_select_all', function() {
				$("div.users-container input.user-cb:checkbox:not(:checked)").attr('checked', true);	
				toggleGroupButtons();
			});
			
			$("div.checkbox_toggler_container").on('click', '.result_deselect_all', function() {
				$("div.users-container input.user-cb:checkbox:checked").attr('checked', false);
				toggleGroupButtons();
			});
			
			$("div.checkbox_toggler_container").on('click', '.result_invert_sel', function() {
				$("div.users-container input.user-cb:checkbox").click();
				toggleGroupButtons();
			});

			$("div.users-container").on('click', 'input.user-cb:checkbox', function() {
				toggleGroupButtons();
			});

			$('table#users_table').on('click', '.user_destroy', function() {
				destroy_user = $(this).data('user-id');
				$('.delete-user-confirm-dlg').modal('show');

				return false;
			});

			$('#del_user_confirm_ok').click(function () {
				var link = "a#user_" + destroy_user + "_destroy_link";
				$(link).click();
				
				$('.delete-user-confirm-dlg').modal('hide');
			});

			$('table#users_table').on('click', '.user_disable', function() {
				disable_user = $(this).data('user-id');

				$('.disable-user-confirm-dlg').modal('show');

				return false;
			});

			$('#disable_user_confirm_ok').click(function () {
				if(bulk_operation) {
					$('form#selected_users_form').submit();
				}
				else {
					var link = "a#user_" + disable_carrier + "_disable_link";
					$(link).click();	
				}
				
				$('.disable-user-confirm-dlg').modal('hide');
				bulk_operation = false;
			});

			$('table#users_table').on('click', '.user_enable', function() {
				enable_carrier = $(this).data('user-id');

				$('.enable-user-confirm-dlg').modal('show');

				return false;
			});

			$('#enable_user_confirm_ok').click(function () {
				if(bulk_operation) {
					$('form#selected_users_form').submit();
				}
				else {
					var link = "a#user_" + enable_carrier + "_enable_link";
					$(link).click();
				}

				$('.enable-user-confirm-dlg').modal('hide');
				bulk_operation = false;
			});

			$('button.btn_change_all_status').click(function() {
				bulk_operation = true;
				$('form#selected_users_form').attr('action', $(this).data('url'));
			});

			$('#users_table').DataTable({
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
							$(td).addClass('text-center').html('<input type="checkbox" name="user_ids[]" class="user-cb" value="'+ cellData +'">');
						}
					},
					
					{
				    	"targets": 6,
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
						"targets": 7,
						"createdCell": function (td, cellData, rowData, row, col) {
							innerHtml = '';
							innerHtml += ' <a class="btn btn-default btn-xs" title="Modify" href="/users/'+ rowData[0] +'/edit_internal"><span class="glyphicon glyphicon-edit"></span></a>';
							
							if(rowData[0] != 1) {
								innerHtml += ' <a href="#" rel="nofollow" data-user-id="'+ rowData[0] +'" title="Delete" class="btn btn-danger btn-xs user_destroy"><span class="glyphicon glyphicon-trash"></span></a> ';
								innerHtml += ' <a href="/users/'+ rowData[0] +'" rel="nofollow" data-remote="true" data-method="delete" id="user_'+ rowData[0] +'_destroy_link"></a>';
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
			    			return $('#users_table').DataTable().page.info().page + 1;
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

			        $(this).find('input.user-cb:checkbox').attr('checked', false);
			        toggleGroupButtons();
			    }
			});
		};

		var toggleGroupButtons = function() {
			if ($("div.users-container input.user-cb:checkbox:checked").length > 0) {
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