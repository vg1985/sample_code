//= require bootstrap.min
//= require modernizr.min
//= require toggles.min
//= require retina.min
//= require jquery.cookies
//= require jquery.validate.min
//= require jquery.datatables.min
//= require select2.min
//= require custom
//= require_self

var App = App || {};

jQuery(document).ready(function() {
    App.CommonViewTicketHandler = (function($) {
        var loadComments = function(url) {
            $.get(url, {}, function(data) {
                $('#comments').html(data);
            }, 'html');
        };

        var initAttachmentsDZ = function(urls, maxfiles) {
            return new Dropzone("div#attachments_cont", {
                //Dropzone.options.auth_files({
                url: urls[0],
                headers: {"X-CSRF-Token" : $('meta[name="csrf-token"]').attr('content')},
                maxFilesize: 3,
                filesizeBase: 1024,
                addRemoveLinks: true,
                uploadMultiple: false,
                maxFiles: maxfiles,
                acceptedFiles: 'image/*,application/pdf',
                dictDefaultMessage: "<h4>Drop Files here</h4> or click here to upload.",
                dictMaxFilesExceeded: "Maximum " + maxfiles + " file(s) can be uploaded.",
                init: function() {
                  this.on("success", function(file, response) { 
                    if (response.status == 'success') {
                      file.token = response.token;  
                      if(this.getAcceptedFiles().length > 0) {
                          //$('.done-btn').removeClass('disabled');
                          $('div#comments').trigger('fileadded');
                      }
                    }
                  });

                  this.on('removedfile', function(file) {
                      if(this.getAcceptedFiles().length < 1) {
                          //$('.done-btn').addClass('disabled');
                      }

                      if(file.token != undefined) {
                          $.get(urls[1], {token: file.token});
                      }
                  });
                },
                fallback: function() {
                  //$('.done-btn').removeClass('disabled');
                },
                forceFallback:  false
            });
        };

        return {
            loadComments: loadComments,
            initAttachmentsDZ: initAttachmentsDZ
        };
    })(jQuery);

    App.SupportTicketCreateHandler = (function($) {
        var urls;

        var init = function() {
          $('#ticket_carrier_id').select2({
            width: '75%'
          }).change(function() {
            $.get('/carriers/' + $(this).val() + '/contact_options',
              {}, null, 'script');
          });

          $('#ticket_cc_to').select2({
            tags: [],
            width: '100%'
          });

          $('#ticket_phone').select2({
            tags: [],
            width: '100%'
          });

          $('#ticket_type').select2({
            width: '75%'
          });

          $('#ticket_priority').select2({
            width: '75%'
          });

          $('#ticket_tags').select2({
            tags: [],
            width: '100%',
            tokenSeparators: [',', ' ']
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
              // do other things for a valid form
              if (true) {
                form.submit();
              }
            },
            rules : {
              "ticket[carrier_id]": {
                required : true,
              },
              "ticket[requester_id]": {
                required : true,
              },
              "ticket[requester_name]": {
                required : true,
                minlength : 2,
                maxlength : 255
              },
              "ticket[subject]": {
                required : true,
                minlength : 10,
              },
              "ticket[type]": {
                required: true
              },
              "ticket[priority]": {
                required: true
              },
              "ticket[comment]": {
                required: true
              }
            },
            messages : {}
          };
          
          $newFormValidator = $('#new_ticket_form').validate(validationOptions);

          initRequester();
          initCCTo([]);
        };

        var initRequester = function() {
          $('#carrier_contacts_list select').select2({
            width: '100%'
          }).change(function() {
            var option = $("option:selected", this).text();
            var name = option.match(/(.+) <.+>/);
            $('#ticket_requester_name').val(name[1]);
          });
        };

        initCCTo = function(tags) {
            console.log(tags);
          $('#ticket_cc_to').select2({
            tags: function() {
              return tags;
            },
            width: '100%'
          });
        };

        initPhones = function(tags) {
          $('#ticket_phone').select2({
            tags: function() {
              return tags;
            },
            width: '100%'
          });
        }

        var setUrls = function(arr) {
          urls = arr;
        };

        return {
          init: init,
          setUrls: setUrls,
          initRequester: initRequester,
          initCCTo: initCCTo,
          initPhones: initPhones
        };
    })(jQuery);

    App.SupportTicketUpdateHandler = (function($) {
        var urls;

        var init = function() {
          $('#ticket_carrier_id').select2({
            width: '75%'
          }).change(function() {
            $.get('/carriers/' + $(this).val() + '/contact_options',
              {}, null, 'script');
          });

          $('#ticket_type').select2({
            width: '75%'
          });

          $('#ticket_priority').select2({
            width: '75%'
          });

          $('#ticket_tags').select2({
            tags: [],
            width: '100%',
            tokenSeparators: [',', ' ']
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
              // do other things for a valid form
              if (true) {
                form.submit();
              }
            },
            rules : {
              "ticket[carrier_id]": {
                required : true,
              },
              "ticket[requester_id]": {
                required : true,
              },
              "ticket[subject]": {
                required : true,
                minlength : 10,
              },
              "ticket[type]": {
                required: true
              },
              "ticket[priority]": {
                required: true
              },
              "ticket[description]": {
                required: true
              }
            },
            messages : {}
          };
          
          $editFormValidator = $('#edit_ticket_form').validate(validationOptions);

          initRequester();
        };

        var initRequester = function() {
          $('#carrier_contacts_list select').select2({
            width: '100%'
          }).change(function() {
            var option = $("option:selected", this).text();
            var name = option.match(/(.+) <.+>/);
            $('#ticket_requester_name').val(name[1]);
          });
        };

        initCCTo = function(tags) {
            $('#ticket_cc_to').select2({
                tags: function() {
                return tags;
                },
                width: '100%'
            });
        };

        var setUrls = function(arr) {
          urls = arr;
        };

        return {
          init: init,
          setUrls: setUrls,
          initRequester: initRequester,
          initCCTo: initCCTo
        };
    })(jQuery);

	App.AdminViewTicketHandler = (function($) {
		var urls, maxfiles = 3, attachmentsDropZone = null;

		var init = function() {
            $('#comments .loader').html(ajax_loader);

            App.CommonViewTicketHandler.loadComments(urls[0]);

            $('button.edit_ticket').click(function() {
                window.location.href = urls[3];
            });

            $('.print-ticket').click(function() {
                window.print();
            });

            $('div#comments').on('click', 'a.make-comment, #submit_btn', function(e) {
                if('submit_btn' == $(e.currentTarget).attr('id')) {
                    var files = 0;
                    if(attachmentsDropZone) {
                        files = attachmentsDropZone.getAcceptedFiles().length;
                    }

                    if($.trim($('#comment_body').val()) == '' 
                        && files < 1) {
                        return false;
                    }
                }

        		$('#comment_status').val($(this).data('status'));
        		$('#submitas_btn, #submit_btn').addClass('disabled');

                if(attachmentsDropZone && $('.fallback').length < 1) {
                    var files = new Array();
                    $.each(attachmentsDropZone.getAcceptedFiles(), function() {
                        files.push(this.token);
                    });

                    $("#comment_uploads").val(files.join(','));
                }

                $('form#make_comment_form').submit();
    	   });

        	$(document).on('click', 'a.close_modal', function() {
        	   $(this).parents('.modal').modal('hide');
        	});
		};
        
        var initAttachmentsDZ = function() {
            attachmentsDropZone = App.CommonViewTicketHandler.initAttachmentsDZ([urls[1], urls[2]], maxfiles);
        };

		var setUrls = function(arr) {
			urls = arr;
		};

		return {
			init: init,
            initAttachmentsDZ: initAttachmentsDZ,
			setUrls: setUrls
		};

	})(jQuery);

	App.AdminViewTicketsHandler = (function($) {
		var urls, destroy_ticket, ticketIds;

		var init = function() {
            App.nav.collapseLeftNav();

			$(document).on('click', 'a.close_modal', function() {
				$(this).parents('.modal').modal('hide');
			});

            $("div.checkbox_toggler_container").on('click', '.result_select_all', function() {
                $("div.support-tickets-container input.ticket-cb:checkbox:not(:checked)").attr('checked', true);  
                toggleGroupButtons();
            });

            $("div.checkbox_toggler_container").on('click', '.result_deselect_all', function() {
                $("div.support-tickets-container input.ticket-cb:checkbox:checked").attr('checked', false);
                toggleGroupButtons();
            });

            $("div.checkbox_toggler_container").on('click', '.result_invert_sel', function() {
                $("div.support-tickets-container input.ticket-cb:checkbox").click();
                toggleGroupButtons();
            });

            $("div.support-tickets-container").on('click', 'input.ticket-cb:checkbox', function() {
                toggleGroupButtons();
            });

            $('#merge_all').click(function() {
                var mergeTicketIds = $("div.support-tickets-container input.ticket-cb:checkbox:checked");
                $('#source_ticket_ids').val('');
                
                if(mergeTicketIds.length < 1) return false;

                ticketIds = new Array();
                var ticketTitles = new Array();
                mergeTicketIds.each(function() {
                  ticketIds.push($(this).val());
                  ticketTitles.push('Ticket#' + $(this).val());
                });

                $('#ticket_ids_info').html(ticketTitles.toSentence());
                $('#source_ticket_ids').val(ticketIds.join(','));
    			$('.merge-ticket-modal').modal('show');
    			return false;
            });

            $.validator.addMethod("notIncludedInSrc", function(value, element) {
                return this.optional(element) || ticketIds.indexOf(value) == -1;
            }, "Target ticket is included in the source ticket.");

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
                    "ticket_id" : {
                        required: true,
                        number: true,
                        notIncludedInSrc: true
                    }
                }
            };

            $('#mergeTicketForm').validate($.extend(true, {}, validationOptions));

            $('table#carriers_table').on('click', '.carrier_enable', function() {
                enable_carrier = $(this).data('carrier-id');

                $('.enable-carrier-confirm-dlg').modal('show');

                return false;
            });

			$('#del_ticket_confirm_ok').click(function () {
				var link = "a#ticket_" + destroy_ticket + "_destroy_link";
				$(link).click();
				
				$('.delete-ticket-confirm-dlg').modal('hide');
			});

    		$("#carrier_select").select2({
  				width: '225px'
  			}).on('change', function() {
				$('#support_tickets_table').DataTable().columns(0).search($(this).val()).draw();
  			});

  			$("#status_select").select2({
  				width: '200px'
  			}).on('change', function() {
				$('#support_tickets_table').DataTable().columns(5).search($(this).val()).draw();
  			});

            $("#priority_select").select2({
                width: '200px'
            }).on('change', function() {
                $('#support_tickets_table').DataTable().columns(4).search($(this).val()).draw();
            });

            $('#support_tickets_table').DataTable({
  				resposive: true,
  				/*"sDom": '<"top"l>rt<"bottom"ip><"clear">',*/
  				"lengthMenu": [ [5, 10, 25, 50, 100], [5, 10, 25, 50, 100] ],
  				"displayLength": 25,
                  "createdRow": function( row, data, dataIndex ) {
                      /*switch(data[4]) {
                        case 'urgent':
                          $(row).find('td').css('background-color', '#ffcccc');
                        break;
                        case 'high':
                          $(row).find('td').css('background-color', '#f8d1b9');
                        break;
                        case 'normal':
                          $(row).find('td').css('background-color', '#ccddff');
                        break;
                        case 'low':
                          $(row).find('td').css('background-color', '#c2f0c2');
                        break;
                        default:
                        break;
                      }*/
                },
  				"columnDefs":[
  					{
                        "targets" : 'no-sort',
                        "orderable" : false,
  			    	},
                    {
                        "targets": 0,
                        "createdCell": function (td, cellData, rowData, row, col) {
                            $(td).addClass('text-center').html('<input type="checkbox" name="ticket_ids[]" class="ticket-cb" value="'+ cellData +'">');
                        }
                    },
  			    	{
  				    	"targets": 5,
  				    	"createdCell": function (td, cellData, rowData, row, col) {
  				    		switch(cellData) {
  				    			case 'urgent':
  				    				$(td).addClass('text-center').html('<span class="label label-danger" title="Critical">Critical</span>');
  				    			break;
  				    			case 'high':
                                    $(td).addClass('text-center').html('<span class="label label-high label-warning" title="High">High</span>');
  				    			break;
  				    			case 'normal':
  				    				$(td).addClass('text-center').html('<span class="label label-info" title="Normal">Normal</span>');
  				    			break;
  				    			case 'low':
  				    				$(td).addClass('text-center').html('<span class="label label-low label-success" title="Low">Low</span>');
  				    			break;
  				    			default:
  				    				$(td).addClass('text-center').html('<span>--</span>');
  				    			break;
  				    		}
  						}
  					},
  					{
  				    	"targets": 6,
  				    	"createdCell": function (td, cellData, rowData, row, col) {
  				    		switch(cellData) {
  				    			case 'pending':
  				    				$(td).addClass('text-center').html('<span class="label label-danger" title="Pending">Pending</span>');
  				    			break;
  				    			case 'open':
  				    			$(td).addClass('text-center').html('<span class="label label-high label-warning" title="Open">Open</span>');
  				    			break;
  				    			case 'new':
  				    				$(td).addClass('text-center').html('<span class="label label-low label-info" title="New">New</span>');
  				    			break;
  				    			case 'hold':
  				    				$(td).addClass('text-center').html('<span>On Hold</span>');
  				    			break;
                                case 'solved':
                                    $(td).addClass('text-center').html('<span class="label label-success" title="Solved">Solved</span>');
                                break;
                                case 'closed':
                                    $(td).addClass('text-center').html('<span>Closed</span>');
                                break;
  				    			default:
  				    				$(td).addClass('text-center').html('<span>--</span>');
  				    			break;
  				    		}
  						}
  					},
  					{
  						"targets": 9,
						"createdCell": function (td, cellData, rowData, row, col) {
                            innerHtml = '';
                            //innerHtml += ' <a class="btn btn-default btn-xs" title="Comment(s)" href="/support/'+ cellData[0] +'#comments">'+ cellData[1] +'</a> | ';
                            innerHtml += '<div class="btn-group">';
                            innerHtml += '<button type="button" class="btn btn-xs btn-primary dropdown-toggle" data-toggle="dropdown">';
  							innerHtml += 'Change Status <span class="caret"></span>';
  							innerHtml += '</button>';
                            innerHtml += '<ul class="dropdown-menu" role="menu">';
                            innerHtml += '<li><a href="/support/' + cellData[0] + '/status?status=open">Open</a></li>';
                            innerHtml += '<li><a href="/support/' + cellData[0] + '/status?status=pending">Pending</a></li>';
                            innerHtml += '<li><a href="/support/' + cellData[0] + '/status?status=solved">Solved</a></li>';
                            if(cellData[3]) {
                                innerHtml += '<li><a href="/support/' + cellData[0] + '/status?status=closed">Closed</a></li>';
                            }
                            
                            innerHtml += '</ul>';
        	              	innerHtml += '</div> | ';
        	              	innerHtml += ' <a class="btn btn-default btn-xs" title="View" href="/support/'+ cellData[0] +'"><span class="glyphicon glyphicon-eye-open"></span></a>';
                            if(cellData[4]) {
                                tags = cellData[1] ? 'Tags: ' + cellData[1] : 'No Tags'
                                
                                innerHtml += ' | <a class="btn btn-default btn-xs" title="'+ tags +'" href="javascript:void(0);"><span class="glyphicon glyphicon-info-sign"></span></a>';
                            }
        	              	if(cellData[2]) {
                                innerHtml += ' |  <a href="#" rel="nofollow" data-ticket-id="'+ cellData[0] +'" title="Delete" class="btn btn-danger btn-xs ticket_destroy"><span class="glyphicon glyphicon-trash"></span></a> ';
                                innerHtml += ' <a href="/support/'+ cellData[0] +'" rel="nofollow" data-method="delete" id="ticket_'+ cellData[0] +'_destroy_link"></a>';  
                            }
		              	
				    	   $(td).html(innerHtml);
						}
                    }
  				],
  			    "order": [[ 8, "desc" ]],
  			    "processing": true,
  			    "serverSide": true,
  			    "ajax": {
  			    	url: urls[0],
  			    	method: 'post',
  			    	data: {
  			    		page: function() {
  			    			return $('#support_tickets_table').DataTable().page.info().page + 1;
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

        var toggleGroupButtons = function() {
            if ($("div.support-tickets-container input.ticket-cb:checkbox:checked").length > 0) {
                $('#merge_all').removeClass('disabled'); 
            }     
            else {
                $('#merge_all').addClass('disabled');
            }
        };

		var setUrls = function(arr) {
            urls = arr;
		};

		return {
            init: init,
			setUrls: setUrls
		};

	})(jQuery);

    App.CarrierViewTicketsHandler = (function($) {
        var urls, destroy_ticket;

        var init = function() {
            App.nav.collapseLeftNav();

            $(document).on('click', 'a.close_modal', function() {
                $(this).parents('.modal').modal('hide');
            });

            $('table#support_tickets_table').on('click', '.ticket_destroy', function() {
                destroy_ticket = $(this).data('ticket-id');

                $('.delete-ticket-confirm-dlg').modal('show');

                return false;
            });

            $('#del_ticket_confirm_ok').click(function () {
                var link = "a#ticket_" + destroy_ticket + "_destroy_link";
                $(link).click();

                $('.delete-ticket-confirm-dlg').modal('hide');
            });

            $("#status_select").select2({
                width: '200px'
            }).on('change', function() {
                $('#support_tickets_table').DataTable().columns(5).search($(this).val()).draw();
            });

            $("#priority_select").select2({
                width: '200px'
            }).on('change', function() {
                $('#support_tickets_table').DataTable().columns(4).search($(this).val()).draw();
            });

            $('#support_tickets_table').DataTable({
                resposive: true,
                /*"sDom": '<"top"l>rt<"bottom"ip><"clear">',*/
                "lengthMenu": [ [5, 10, 25, 50, 100], [5, 10, 25, 50, 100] ],
                "displayLength": 10,
                "createdRow": function( row, data, dataIndex ) {
                    /*switch(data[3]) {
                    case 'urgent':
                      $(row).find('td').css('background-color', '#ffcccc');
                    break;
                    case 'high':
                      $(row).find('td').css('background-color', '#f8d1b9');
                    break;
                    case 'normal':
                      $(row).find('td').css('background-color', '#ccddff');
                    break;
                    case 'low':
                      $(row).find('td').css('background-color', '#c2f0c2');
                    break;
                    default:
                    break;
                    }*/
                },
                "columnDefs":[
                    {
                        "targets" : 'no-sort',
                        "orderable" : false,
                    },
                    {
                        "targets": 3,
                        "createdCell": function (td, cellData, rowData, row, col) {
                            switch(cellData) {
                                case 'urgent':
                                    $(td).addClass('text-center').html('<span class="label label-danger" title="Critical">Critical</span>');
                                break;
                                case 'high':
                                    $(td).addClass('text-center').html('<span class="label label-high label-warning" title="High">High</span>');
                                break;
                                case 'normal':
                                    $(td).addClass('text-center').html('<span class="label label-info" title="Normal">Normal</span>');
                                break;
                                case 'low':
                                    $(td).addClass('text-center').html('<span class="label label-low label-success" title="Low">Low</span>');
                                break;
                                default:
                                    $(td).addClass('text-center').html('<span>--</span>');
                                break;
                            }
                        }
                    },
                    {
                        "targets": 4,
                        "createdCell": function (td, cellData, rowData, row, col) {
                            switch(cellData) {
                                case 'pending':
                                    $(td).addClass('text-center').html('<span class="label label-danger" title="Pending">Pending</span>');
                                break;
                                case 'open':
                                $(td).addClass('text-center').html('<span class="label label-high label-warning" title="Open">Open</span>');
                                break;
                                case 'new':
                                    $(td).addClass('text-center').html('<span class="label label-low label-info" title="New">New</span>');
                                break;
                                case 'hold':
                                    $(td).addClass('text-center').html('<span>On Hold</span>');
                                break;
                                case 'solved':
                                    $(td).addClass('text-center').html('<span class="label label-success" title="Solved">Solved</span>');
                                break;
                                case 'closed':
                                    $(td).addClass('text-center').html('<span>Closed</span>');
                                break;
                                default:
                                    $(td).addClass('text-center').html('<span>--</span>');
                                break;
                            }
                        }
                    },
                    {
                        "targets": 7,
                        "createdCell": function (td, cellData, rowData, row, col) {
                            innerHtml = '';
                            //innerHtml += ' <a class="btn btn-default btn-xs" title="Comment(s)" href="/support/'+ cellData[0] +'#comments">'+ cellData[1] +'</a> | ';
                            innerHtml += '<div class="btn-group">';
                            innerHtml += '<button type="button" class="btn btn-xs btn-primary dropdown-toggle" data-toggle="dropdown">';
                            innerHtml += 'Change Status <span class="caret"></span>';
                            innerHtml += '</button>';
                            innerHtml += '<ul class="dropdown-menu" role="menu">';
                            innerHtml += '<li><a href="/support/' + cellData[0] + '/status?status=open">Open</a></li>';
                            innerHtml += '<li><a href="/support/' + cellData[0] + '/status?status=pending">Pending</a></li>';
                            innerHtml += '<li><a href="/support/' + cellData[0] + '/status?status=solved">Solved</a></li>';
                            if(cellData[3]) {
                                innerHtml += '<li><a href="/support/' + cellData[0] + '/status?status=closed">Closed</a></li>';    
                            }
                            innerHtml += '</ul>';
                            innerHtml += '</div> | ';
                            innerHtml += ' <a class="btn btn-default btn-xs" title="View" href="/support/'+ cellData[0] +'"><span class="glyphicon glyphicon-eye-open"></span></a>';

                            if(cellData[4]) {
                                tags = cellData[1] ? 'Tags: ' + cellData[1] : 'No Tags'
                                    
                                innerHtml += ' | <a class="btn btn-default btn-xs" title="'+ tags +'" href="javascript:void(0);"><span class="glyphicon glyphicon-info-sign"></span></a>';
                            }
                            if(cellData[2]) {
                                innerHtml += ' |  <a href="#" rel="nofollow" data-ticket-id="'+ cellData[0] +'" title="Delete" class="btn btn-danger btn-xs ticket_destroy"><span class="glyphicon glyphicon-trash"></span></a> ';
                                innerHtml += ' <a href="/support/'+ cellData[0] +'" rel="nofollow" data-method="delete" id="ticket_'+ cellData[0] +'_destroy_link"></a>';  
                            }
                              
                            $(td).html(innerHtml);
                        }
                    }
                ],
                "order": [[ 6, "desc" ]],
                "processing": true,
                "serverSide": true,
                "ajax": {
                  url: urls[0],
                  method: 'post',
                  data: {
                      page: function() {
                          return $('#support_tickets_table').DataTable().page.info().page + 1;
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
                    } 
                    else {
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

    App.CarrierViewTicketHandler = (function($) {
        var urls, maxfiles = 3, attachmentsDropZone = null;

        var init = function() {
            $('#comments .loader').html(ajax_loader);

            App.CommonViewTicketHandler.loadComments(urls[0]);

            $('button.edit_ticket').click(function() {
                window.location.href = urls[3];
            });

            $('.print-ticket').click(function() {
                window.print();
            });
            
            $('div#comments').on('click', 'a.make-comment, #submit_btn', function(e) {
                if('submit_btn' == $(e.currentTarget).attr('id')) {
                    var files = 0;
                    if(attachmentsDropZone) {
                      files = attachmentsDropZone.getAcceptedFiles().length;
                    }

                    if($.trim($('#comment_body').val()) == '' 
                      && files < 1) {
                        
                        return false;
                    }
                }

                $('#comment_status').val($(this).data('status'));
                $('#submit_btn, #submit_btn').addClass('disabled');

                if(attachmentsDropZone && $('.fallback').length < 1) {
                  var files = new Array();
                  $.each(attachmentsDropZone.getAcceptedFiles(), function() {
                      files.push(this.token);
                  });

                  $("#comment_uploads").val(files.join(','));
                }

                $('form#make_comment_form').submit();
            });

            //attachmentsDropZone = App.CommonViewTicketHandler.initAttachmentsDZ([urls[1], urls[2]], maxfiles);

            $(document).on('click', 'a.close_modal', function() {
                $(this).parents('.modal').modal('hide');
            });
    };

    var initAttachmentsDZ = function() {
        attachmentsDropZone = App.CommonViewTicketHandler.initAttachmentsDZ([urls[1], urls[2]], maxfiles);
    };

    var setUrls = function(arr) {
        urls = arr;
    };

    return {
        init: init,
        initAttachmentsDZ: initAttachmentsDZ,
        setUrls: setUrls
    };

  })(jQuery);
});

