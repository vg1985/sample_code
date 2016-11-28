var App = App || {};

jQuery(document).ready(function() {
	App.DidSettings = (function($) {
		var messages = [], ingressTrunksList, canChangeDefaults;

		var init = function(options) {
			canChangeDefaults = options[0];

			$('.did-voice-settings-dlg').on('show.bs.modal', function(e) {
				var url = $(e.relatedTarget).data('settings-url');
				$(".did-voice-settings-dlg .modal-content").html('<div class="text-center">'+ ajax_loader + '</div>');
				$.get(url, function(data) {
					$(".did-voice-settings-dlg .modal-content").html(data);
				});
			});

			$('.did-sms-settings-dlg').on('show.bs.modal', function(e) {
				var url = $(e.relatedTarget).data('settings-url');
				var send_dids = $(e.relatedTarget).data('send-dids');

				$(".did-sms-settings-dlg .modal-content").html('<div class="text-center">'+ ajax_loader + '</div>');

				query_data = {};

				if(send_dids) {
					query_data.dids = getSelectedDids();
				}

				$.get(url, query_data, function(data) {
					$(".did-sms-settings-dlg .modal-content").html(data);
					$("#sms_activation_tgl").toggles({ on: $('#sms_activation_tgl_chkbox').is(':checked'),
						checkbox: $("#sms_activation_tgl_chkbox"), 'event': 'toggle', 
						text: {on: "Yes", off: "No"}});
					if($("#sms_activation_tgl_chkbox").is(':checked')) {
						$('#cb_agree_cont').show();
						tglSMSSettingSbmt(true);
					}
					else {
						$('#cb_agree_cont').hide();
						tglSMSSettingSbmt(false);
					}
					

					$('#cb_agree').change(function() {
						tglSMSSettingSbmt($("#sms_activation_tgl_chkbox").is(':checked'));
					});

					$("#sms_activation_tgl").on("toggle", function(e) {
						var activated = $("#sms_activation_tgl_chkbox").is(':checked')
						if(activated) {
							$('#cb_agree_cont').show();
							tglSMSSettingSbmt(true);
						}
						else {
							$('#cb_agree_cont').hide();
							tglSMSSettingSbmt(false);	
						}
						
					});
				});
			});

			$('.did-voice-settings-dlg').on('click', '.dest-opn', function() {

				if($("table#voice_destination_table tbody tr").length > 3 || $("table#voice_destination_table tbody tr:last").data('option') == '1') {
					return;
				}

				var option = $(this).data('option');
				var desc = "<td><textarea rows='1' cols='20' name='did_settings[desc][]'></textarea></td>";
				if(canChangeDefaults) {
					var try_timeout = "<td><input type='number' class='input-sm tooltips dest-try-timeout' data-placement='top' data-toggle='tooltip' style='width:75%' name='did_settings[try_timeout][]' title='"+ messages[0] +"'/></td>";
					var pdd_timeout = "<td><input type='number' class='input-sm dest-pdd-timeout tooltips' data-placement='top' data-toggle='tooltip'  style='width:75%' name='did_settings[pdd_timeout][]' title='"+ messages[1] +"'/></td>";	
				}
				else {
					var try_timeout = "<td class='text-center'><span>"+ options[2] +"</span></td>";
					var pdd_timeout = "<td class='text-center'><span>"+ options[1] +"</span></td>";
				}
				
				var delete_action = "<td class='table-action'> \
	    								<a class='delete-row' href='#' title='Remove'>\
	    									<i class='glyphicon glyphicon-trash'></i>\
	    								</a>\
	    							</td>";
				switch(option) {
					case 1:
						var dest_type = "<td>Call Forwarding <input type='hidden' name='did_settings[type][]' value='"+ option +"' /></td>";
						var dest_val = "<td><input type='text' name='did_settings[value][]' data-placement='top' data-toggle='tooltip' class='dest-val tooltips' size='20' title='"+ messages[2] +"'/></td>";
					break;

					case 2:
						var dest_type = "<td>Trunk  <input type='hidden' name='did_settings[type][]' value='"+ option +"' /></td>";
						var dest_val = "<td><select name='did_settings[value][]' data-placeholder='Please Select' class='dest-val'>"+ ingressTrunksList +"</select></td>";
					break;

					case 3:
						var dest_type = "<td>IP/Domain  <input type='hidden' name='did_settings[type][]' value='"+ option +"' /></td>";
						var dest_val = "<td><input type='text' name='did_settings[value][]' data-placement='top' data-toggle='tooltip' class='tooltips dest-val' title='"+ messages[3] +"' /></td>";
					break;
				}

				var row = '<tr data-option="'+ option +'">' + dest_type + dest_val + desc + try_timeout + pdd_timeout + delete_action + '</tr>';
				$("table#voice_destination_table tbody").append(row);

				var appended_row = $("table#voice_destination_table tbody tr:last");
				appended_row.find("select.dest-val").select2({width: '100%'});
				
				if($("table#voice_destination_table tbody tr").length > 2 || appended_row.data('option') == '1') {
					$(".add-dest-btn").addClass('disabled');

					if(appended_row.data('option') == '1') {
						$("#callfwd_type_msg").show();	
					}
					
				}

				appended_row.find('.tooltips').tooltip({ container: 'body'});
				
				$(".nodest-msg").hide();
				$("table#voice_destination_table").show();
				$('#voice_settings_submit_btn').removeClass('disabled');

			});
			
			$('.did-voice-settings-dlg').on('click', 'a.delete-row', function() {
				parent_row = $(this).parents('tr');
				parent_row.remove();
				
				if($("table#voice_destination_table tbody tr").length < 3 && $("table#voice_destination_table tbody tr:last").data('option') != '1') {
					$(".add-dest-btn").removeClass('disabled');
					$("#callfwd_type_msg").hide();
				}

				if($("table#voice_destination_table tbody tr").length < 1) {
					$(".nodest-msg").show();
					$("table#voice_destination_table").hide();
					$('#voice_settings_submit_btn').addClass('disabled');
				}

				$('.settings-err-msg').hide();
			});
		}

		var tglSMSSettingSbmt = function(activated) {
			if(activated) {
				$("#sms_settings_submit_btn").attr('disabled', !$('#cb_agree').is(":checked"));
			}
			else {
				$("#sms_settings_submit_btn").attr('disabled', false);	
			}
		}

		var getSelectedDids = function() {
			return $("div#did_groups_container input.did-cb:checkbox:checked").map(function() {
				return $(this).val();
			}).get();
		}

		var submitVoiceSettings = function(bulk_settings) {
			var error = false;

			$("table#voice_destination_table tbody tr").each(function() {
				var option = $(this).data('option');
				var dest_val;
				$('.settings-err-msg').hide();

				dest_try_timeout = $(this).find('.dest-try-timeout');
				dest_pdd_timeout = $(this).find('.dest-pdd-timeout');
				
				dest_try_timeout.removeClass('settings-error');
				dest_pdd_timeout.removeClass('settings-error');

				switch(option) {
					case 1: 
						dest_val = $(this).find('.dest-val');
						dest_val.removeClass('settings-error');

						if($.trim(dest_val.val()) == '' || dest_val.val().length < 3 || dest_val.val().length > 200) {
							dest_val.addClass('settings-error');
							error = true;
						}
					break;

					case 3:
						dest_val = $(this).find('.dest-val');
						dest_val.removeClass('settings-error');

						if($.trim(dest_val.val()) == '' || !( /^[a-z0-9\.\-]+$/i.test(dest_val.val()))) {
							dest_val.addClass('settings-error');
							error = true;
						}
					break;

					case 2:
						dest_val = $(this).find('select.dest-val');
						$(this).find('.select2-container').removeClass('settings-error')
						if(dest_val.val() == '') {
							$(this).find('.select2-container').addClass('settings-error');
							error = true;
						}
					break;
				}

				if(canChangeDefaults && (!(/^\d+$/.test(dest_try_timeout.val())) || parseInt(dest_try_timeout.val()) < 3 || parseInt(dest_try_timeout.val()) > 60)) {
					dest_try_timeout.addClass('settings-error');
					error = true;
				}

				if(canChangeDefaults && (!(/^\d+$/.test(dest_pdd_timeout.val())) || parseInt(dest_pdd_timeout.val()) < 3 || parseInt(dest_pdd_timeout.val()) > 60)) {
					dest_pdd_timeout.addClass('settings-error');
					error = true;
				}
			});

			if(error) {
				$('.settings-err-msg').show();
			}
			else {
				if(bulk_settings) {
					dids = getSelectedDids();
					if(dids.length < 1) {
						return false;	
					}

					$('#bulk_setting_dids').val(dids);
				}

				$('form#voice_settings_form').submit();
			}
		};

		var submitSmsSettings = function(bulk_settings) {
			var error = false;
			var enable = $('#sms_activation_tgl_chkbox').is(':checked');
			var dest_val = $('input#did_setting_value');

			$('.settings-err-msg').hide();
			dest_val.removeClass('settings-error');
			
			var dest_type = $("select#did_setting_type").val();
			
			switch(dest_type) {
				case '1':
					if(enable) {
						if($.trim(dest_val.val()) == '' || /\D/.test(dest_val.val())) {
							dest_val.addClass('settings-error');
							error = 'Destination value is required and should be a valid number.';
						}
					}
					else {
						if($.trim(dest_val.val()) != '' && /\D/.test(dest_val.val())) {
							dest_val.addClass('settings-error');
							error = 'Destination value can be blank or should be a valid number.';
						}
					}
				break;
				case '2':
					if(enable) {
						if($.trim(dest_val.val()) == '' || !( /^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/i.test(dest_val.val()))) {
							dest_val.addClass('settings-error');
							error = 'Destination value is required and should be a valid email address.';
						}
					}
					else {
						if($.trim(dest_val.val()) != '' && !( /^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/i.test(dest_val.val()))) {
							dest_val.addClass('settings-error');
							error = 'Destination value can be blank or should be a valid email address.';
						}
					}
				break;
				case '3':
					if(enable) {
						if($.trim(dest_val.val()) == '' || !( /^https?\:\/\/[^\/\s]+(\/.*)?$/i.test(dest_val.val()))) {
							dest_val.addClass('settings-error');
							error = 'Destination value is required and  should be a valid URL.';
						}
					}
					else {
						if($.trim(dest_val.val()) != '' && !( /^https?\:\/\/[^\/\s]+(\/.*)?$/i.test(dest_val.val()))) {
							dest_val.addClass('settings-error');
							error = 'Destination value can be blank or should be a valid URL.';
						}
					}
				break;
			}
			
			if(error) {
				$('.settings-err-msg').html('Error: ' + error).show();
			}
			else {
				if(bulk_settings) {
					dids = getSelectedDids();
					if(dids.length < 1) {
						return false;	
					}

					$('#bulk_setting_dids').val(dids);
				}

				$('form#sms_settings_form').submit();
			}
		};

		var initSMSDestinations = function() {
			$("select#did_setting_type").select2({
  				width: '150px'
  			}).on('change', function() {
				var value = $(this).val();
				
				switch(value) {
					case '1':
						$('input#did_setting_value').attr('data-original-title', messages[4]).val('');
					break;
					case '2':
						$('input#did_setting_value').attr('data-original-title', messages[5]).val('');
					break;
					case '3':
						$('input#did_setting_value').attr('data-original-title', messages[6]).val('');
					break;
				}
  			});
		}

		var setIngressTrunksList = function(options) {
			ingressTrunksList = '<option value=""></option>' + options;
		};

		var setMessages = function(arr) {
			messages = arr;
		}

		return {
			init: init,
			initSMSDestinations: initSMSDestinations,
			submitVoiceSettings: submitVoiceSettings,
			submitSmsSettings: submitSmsSettings,
			setIngressTrunksList: setIngressTrunksList,
			setMessages: setMessages
		}
	})(jQuery);
});