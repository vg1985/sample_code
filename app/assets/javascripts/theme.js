//= require bootstrap.min
//= require modernizr.min
//= require jquery.sparkline.min
//= require toggles.min
//= require retina.min
//= require jquery.cookies

//= require flot/flot.min
//= require flot/flot.resize.min
//= require flot/flot.symbol.min
//= require flot/flot.crosshair.min
//= require flot/flot.categories.min
//= require flot/flot.pie.min

//= require morris.min
//= require raphael.min
//= require chosen.jquery

//= require jquery_nested_form

//= require 'wysihtml5-0.3.0.min'
//= require 'bootstrap-wysihtml5'

//= require 'ckeditor/ckeditor'
//= require 'ckeditor/adapters/jquery'

//= require moment
//= require bootstrap-datetimepicker
//= require bootstrap-wizard.min
//= require bootstrap-editable
//= require bootstrap-editable-rails

//= require 'jquery.tagsinput.min'
//= require 'jquery.validate.min'
  
//= require dataTables/jquery.dataTables
//= require multi-select
//= require jquery.gritter.min

//= require custom

var App = App || {};

App.nav = {
  collapseLeftNav: function(){
    $('body').addClass('leftpanel-collapsed');
  },
  openLeftNav: function(){
    $('body').removeClass('leftpanel-collapsed');
  }
};

App.ErrorHandler = {
  add_errors: function(container_id, error_hash){
    $el = $(container_id);
    this.clear_errors(container_id);
    errors = JSON.parse(error_hash);
    $.each(errors, function(key,errors_arr) {
      $input = $el.find("[data-errorkey="+"\""+key+"\""+"]");
      $input.closest(".form-group .col-sm-7").append("<span class='error'>"+errors_arr.join(", ")+"</span>");
    });
  },

  clear_errors: function(container_id){
    $(container_id).find("span.error").each(function(){
      $(this).remove();
    });
  }
};

App.ToggleHandler = {
  init: function(){
    $('.toggle').on('toggle', function(e, active){
      var el_id = $(e.target).data("selector");
      if (active) {
        $('#' + el_id).val('1');
      } else {
        $('#' + el_id).val('0');
      }
    });
  }
};


$(document).ready(function() {

  $('.select_all').click(function(e) {
    $(':checkbox').each(function() {
        this.checked = !this.checked;
    });
  });

  $('#carrier_select').multiSelect();
  $('#datepicker').datetimepicker({format: 'YYYY/MM/DD hh:mm:ss'});

  $(document).on('click', '#carrier_list a', function(e){
    $("#carrier_list li").removeClass("active");
    $(e.target).closest('li').addClass('active');
  });

  $(document).on('click', '.remove_nested_fields', function(){
    $(this).parents('.fields').hide();
  });

  $(document).on('click', '.apply-all', function(e){
    e.preventDefault();
    $('#apply-all').modal('show');
  });

  $(document).on('click', '.apply-selected', function(e){
    e.preventDefault();
    $('#apply-selected').modal('show');
  });

  $(document).on('click', '.delete-selected', function(e){
    e.preventDefault();
    $('#delete-selected').modal('show');
  });
});

function toggle_rate_fields($display, $fields) {
  $display.toggle();
  $fields.toggle();
}
function show_edit_options() {
  $("#batch-edit-options").toggle();
}
function show_import_options() {
  $("#import-options").toggle();
}
function show_notes() {
  $("#notes-form").toggle();
}

$.rails.allowAction = function(element) {
  var $link, $modal_html, message, modal_html;
  message = element.data('confirm');
  
  if (!message) {
    $("#myModal").modal('hide');
    return true;
  }
  
  $link = element.clone().removeAttr('class').removeAttr('data-confirm').addClass('btn').addClass('btn-danger').html("Delete");
  modal_html = "<div class=\"modal\" id=\"myModal\">\n  <div class=\"modal-dialog\">\n <div class=\"modal-content\">\n <div class=\"modal-header\">\n    <a class=\"close\" data-dismiss=\"modal\">×</a>\n    <h3>" + message + "</h3>\n  </div>\n  <div class=\"modal-body\">\n    <p>Are you sure you want to delete the selected record(s)?</p>\n  </div>\n  <div class=\"modal-footer\">\n    <a data-dismiss=\"modal\" class=\"btn\">Cancel</a>\n  </div>\n</div>\n</div>\n</div>";
  $modal_html = $(modal_html);
  $modal_html.find('.modal-footer').append($link);
  $modal_html.modal();
  return false;
}
