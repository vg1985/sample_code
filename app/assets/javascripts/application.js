// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or any plugin's vendor/assets/javascripts directory can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file.
//
// Read Sprockets README (https://github.com/sstephenson/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require jquery.min
//= require jquery-migrate.min
//= require jquery-ui.min
//= require jquery_ujs
//= require select2.min

var App = App || {};

if (typeof String.prototype.truncate != 'function') {
  String.prototype.truncate = function(n,useWordBoundary) {
     var toLong = this.length > n,
         s_ = toLong ? this.substr(0,n-1) : this;
     s_ = useWordBoundary && toLong ? s_.substr(0,s_.lastIndexOf(' ')) : s_;
     return  toLong ? s_ + '...' : s_;
  };
}

if (typeof String.prototype.startsWith != 'function') {
  String.prototype.startsWith = function (str){
    return this.indexOf(str) === 0;
  };
}

if (typeof Array.prototype.toSentence != 'function') {
  Array.prototype.toSentence = function() {
    return this.join(", ").replace(/,\s([^,]+)$/, ' and $1');
  }
}

jQuery(window).load(function() {
	"use strict";

	// Page Preloader
	jQuery('#preloader').delay(350).fadeOut(function() {
		jQuery('body').delay(350).css({
			'overflow' : 'visible'
		});
	});

	if ( typeof String.prototype.startsWith != 'function') {
		String.prototype.startsWith = function(str) {
			return this.substring(0, str.length) === str;
		};
	};

	if ( typeof String.prototype.endsWith != 'function') {
		String.prototype.endsWith = function(str) {
			return this.substring(this.length - str.length, this.length) === str;
		};
	};

});

jQuery(document).ready(function() {
  jQuery(document).on('click', '.sip-style-selectable .table-hover > tbody > tr', function() {
    $(this).toggleClass('checked');
  });

  $('#masq_user_select').select2({
    width: '100%',
    minimumInputLength: 4,
    placeholder: 'Start typing name',
    ajax: {
      url: '/users/search',
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
              if (item.company_name) {
                return {
                    text: item.username + " (" + item.company_name + ")",
                    //slug: item.slug,
                    id: item.id
                }  
              }
              else {
                return {
                    text: item.username + " (" + item.name + ")",
                    //slug: item.slug,
                    id: item.id
                }
              }
          })
        }
      }
    }
  }).on('change', function() {
    window.location.href = "/users/masquerade/" + $(this).val();
  });
});

function randomAlphaString(length) {
    var text = "";
    var possible = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";

    for( var i=0; i < length; i++ )
        text += possible.charAt(Math.floor(Math.random() * possible.length));

    return text;
}

App.overlayModal = {
    pleaseWaitDiv: jQuery('<div class="modal bar" id="pleaseWaitDialog" data-backdrop="static" data-keyboard="false"><div class="modal-body"><div class="vertical-align"><i class="fa fa-spinner fa-spin" style="font-size: 50px;"></i><h3>Processing...</h3></div></div></div>'),
    
    show: function() {
      this.pleaseWaitDiv.modal('show');
    },

    hide: function () {
      this.pleaseWaitDiv.modal('hide');
    }
};

App.nav = {
  collapseLeftNav: function(){
    jQuery('body').addClass('leftpanel-collapsed');
    jQuery('.nav-bracket .children').css({display: ''});
  },
  openLeftNav: function(){
    jQuery('body').removeClass('leftpanel-collapsed');
  }
};

App.alphaOnlyRegex = /^[a-z0-9\-\s]+$/i;
App.alphaNoSpaceRegex = /^[a-z0-9]+$/i;
App.oneSpecialCharRegex = /[!,@,#,$,%,\^,&,*,?,_,~]/;
App.unformattedMobileRegex = /[()\ -]/g;

var myApp; 
myApp = myApp || (function () {
   
    return {
        showPleaseWait: function() {
            pleaseWaitDiv.modal('show');
        },
        hidePleaseWait: function () {
            pleaseWaitDiv.modal('hide');
        },

    };
})();

