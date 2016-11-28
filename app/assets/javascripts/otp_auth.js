var App = App || {};

$(document).ready(function() {
	var otpid;

	App.OTPAuth = (function($) {
		var action, submitCallback, timer, deactivate = true;

		var init = function(type) {
			if (typeof(type) === 'undefined') type = 'rmobem';
			var data = {};

			$('.otp-auth-dlg').on('show.bs.modal', function (e) {
				var loadUrl;

				switch(type) {
					case 'rmobem':
						loadUrl = "/otps/auth_dialog";
					break;
					case 'rmobemp':
						loadUrl = "/otps/primary_auth_dialog";
					break;
					case 'umobem':
						loadUrl = "/otps/uemobile_auth_dialog";
						data = {
							element: $('#oauth_element').val(),
							value: $('#oauth_element_val').val(),
							a: action
						};
					break;
				}

				$('.otp-auth-dlg .modal-content').load(loadUrl, data);
			});

			$('.otp-auth-dlg').on('hide.bs.modal', function (e) {
				clearInterval(timer);
			});
		};

		var showDialog = function(a, callback) {
			action = a;
			submitCallback = callback;
			$('.otp-auth-dlg').modal('show');
		};

		var hideDialog = function() {
			$('a#cancel_otp_btn2').click();
		}

		var initAuthDlg = function(config) {
			$("#select_otp_mobile, #select_otp_email").select2({
    			width: '90%'
  			}).on('change', function() {
  				$('#send_otp_btn').removeClass('disabled');
  			});

  			$('input[name="send_via"]').click(function() {
  				var via = $(this).val();

  				if ("sms" == via) {
  					$(".mobile_options").show();
  					$(".email_options").hide();
  				}
  				else {
  					$(".mobile_options").hide();
  					$(".email_options").show();
  				}
  			});

  			$(document).on('click', 'a#cancel_otp_btn1, a#cancel_otp_btn2', function() {
				$(this).parents('.modal').modal('hide');
			});

  			$('#send_otp_btn').click(function() {
				$(this).addClass('disabled');

				var postData = {a: action};

				if(config[0] && config[1]) {
					postData.via = $('input[name="send_via"]:checked').val();
					postData.mobile = $('#select_otp_mobile').val();
					postData.email = $('#select_otp_email').val()
				}
				else if(config[0] && !config[1]) {
					postData.via = 'email'
					postData.email = $('#select_otp_email').val()
				}
				else {
					postData.via = 'sms'
					postData.mobile = $('#select_otp_mobile').val()
				}

				$.getJSON('/otps/generate', postData, function(data) {
					if(data.response == 'success') {
						$('a#cancel_otp_btn1').hide();
						$('#otp_auth_dlg_message').html(data.message);
						otpid = data.id;
						$('#otp_id').html(otpid);
						//$('#otp_id').html(otpid + ' (Use code ' +  data.code + ' for testing)');
						$('#otp_fields').show();
						deactivate = false;
						startTimer();
					}
					else {
						$('#otp_auth_dlg_message').html(data.message);
					}
				});
			});

			$('#otp_code').keyup(function() {
				if(deactivate) return;

				if($.trim($(this).val()) == '') {
					$('#submit_otp_btn').addClass('disabled');
				}
				else {
					$('#submit_otp_btn').removeClass('disabled');
				}
			});

  			$('#submit_otp_btn').click(function(e) {
  				if($.trim($('#otp_code').val()) == '') {
  					e.stopImmediatePropagation();
  				}
  			});

			$('#submit_otp_btn').click(submitCallback);
		};

		var initUnRegAuthDlg = function(attr) {
			deactivate = false;

  			$(document).on('click', 'a#cancel_otp_btn1, a#cancel_otp_btn2', function() {
				$(this).parents('.modal').modal('hide');
			});

  			startTimer();

  			$('#otp_code').keyup(function() {
				if(deactivate) return;

				if($.trim($(this).val()) == '') {
					$('#submit_otp_btn').addClass('disabled');
				}
				else {
					$('#submit_otp_btn').removeClass('disabled');
				}
			});

  			$('#submit_otp_btn').click(function(e) {
  				if($.trim($('#otp_code').val()) == '') {
  					return;
  				}
  				var data = {
  					otp_id: $('#otp_id').html(),
  					otp_code: $('#otp_code').val(),
  					a: action,
  					element: attr
  				};

  				$.post('/carriers/unreg_verify_otp', data, function(response) {
  					$('a#cancel_otp_btn2').click();
  					submitCallback(response);
  				}, 'json')
  			});
		};

		var startTimer = function() {
			var startTime = new Date();
			startTime = startTime.getMinutes() * 60 + startTime.getSeconds() + 300 //5 minutes;

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
        			$('#time_left').addClass('text-danger').html('OTP has expired. To regenerate, please cancel this window and submit the form again.');
        			deactivate = true;
        			$('#submit_otp_btn').addClass('disabled');
        			return;
    			}

			    $('#time_left').html(result);

			}, 500);
		};

		var getOTPId = function() {
			return otpid;
		}

		var getOTPCode = function() {
			return $('#otp_code').val();
		}

		var leftPad = function (aNumber) { 
			return (aNumber < 10) ? "0" + aNumber : aNumber;
		};

		return {
			init: init,
			showDialog: showDialog,
			hideDialog: hideDialog,
			initAuthDlg: initAuthDlg,
			initUnRegAuthDlg: initUnRegAuthDlg,
			getOTPId: getOTPId,
			getOTPCode: getOTPCode
		};
			
	})(jQuery);
});