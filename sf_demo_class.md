```Abap

*&---------------------------------------------------------------------*
*& Include          ZAB_SF_DEMO2_CL_MAIN
*&---------------------------------------------------------------------*

CLASS zab_get_data_sf_user DEFINITION.
  PUBLIC SECTION.

    CLASS-DATA lt_data_json      TYPE zab_get_user.
    CLASS-DATA gv_response      TYPE string.


    CLASS-METHODS get_sf_data.
    CLASS-METHODS get_sap_data.
    CLASS-METHODS compare_data.
    CLASS-METHODS display_alv.

    CLASS-METHODS get_user_data
      RETURNING
        VALUE(rt_user_data) TYPE zab_tt_get_user. " Kullanıcı verisini döndürme metodu


  PRIVATE SECTION.
    CLASS-METHODS:
      create_http_client
        IMPORTING
          url           TYPE string
        RETURNING
          VALUE(client) TYPE REF TO if_http_client,
      prepare_request
        IMPORTING
          client       TYPE REF TO if_http_client
          auth_token   TYPE string
          content_type TYPE string,
      send_request
        IMPORTING
          client          TYPE REF TO if_http_client
        RETURNING
          VALUE(response) TYPE string,
      log_response
        IMPORTING
          response TYPE string
          status   TYPE i.


    CLASS-DATA lt_sap_data_0000 TYPE STANDARD TABLE OF pa0000.
    CLASS-DATA lt_sap_data_0001 TYPE STANDARD TABLE OF pa0001. " Org Bilgileri
    CLASS-DATA lt_sap_data_0002 TYPE STANDARD TABLE OF pa0002. " Ad Soyad Bilgileri
    CLASS-DATA: lt_sap_missing TYPE TABLE OF zab_get_user,
                lt_sf_missing  TYPE TABLE OF zab_get_user.


ENDCLASS.

CLASS zab_get_data_sf_user IMPLEMENTATION.

  METHOD get_sf_data.
    DATA: lo_http_client      TYPE REF TO if_http_client,
          lv_response         TYPE string,
          ev_xstring          TYPE xstring,
          lv_http_return_code TYPE i.


    SELECT * FROM zab_get_user INTO TABLE gt_sf_data.

    CHECK 1 = 0.

    " 1. HTTP client oluştur
*    lo_http_client = create_http_client( url = user_link ).
    lo_http_client = create_http_client( url = p_link ).

    " 2. İstek yapılandır
    prepare_request(
      client       = lo_http_client
      auth_token   = p_auth
      content_type = p_cont ).

    " 3. İstek gönder ve yanıt al
    lv_response = send_request( client = lo_http_client ).
    gv_response = lv_response.
    " 4. Yanıtı işle
    lo_http_client->response->get_status( IMPORTING code = lv_http_return_code ).
    log_response( response = lv_response status = lv_http_return_code ).


    " 5. Yanıtı XML olarak parse et

    DATA : lt_result_xml TYPE TABLE OF smum_xmltb,
           lt_return     TYPE TABLE OF bapiret2.

*    *Convert STRING to XSTRING

    TYPES: BEGIN OF ty_metadata,
             uri  TYPE string,
             type TYPE string,
           END OF ty_metadata.
    TYPES: BEGIN OF ty_phonenav_results,
             __metadata  TYPE ty_metadata,
             phonenumber TYPE string,
           END OF ty_phonenav_results.
    TYPES ty_tt_phonenav_results TYPE STANDARD TABLE OF ty_phonenav_results WITH NON-UNIQUE DEFAULT KEY.
    TYPES: BEGIN OF ty_phonenav,
             results TYPE ty_tt_phonenav_results,
           END OF ty_phonenav.
    TYPES: BEGIN OF ty_empinfo_personnav,
             __metadata TYPE ty_metadata,
             phonenav   TYPE ty_phonenav,
           END OF ty_empinfo_personnav.
    TYPES: BEGIN OF ty_empinfo,
             __metadata TYPE ty_metadata,
             personnav  TYPE ty_empinfo_personnav,
           END OF ty_empinfo.
    TYPES: BEGIN OF ty_nationalidnav_results,
             __metadata TYPE ty_metadata,
             nationalid TYPE string,
           END OF ty_nationalidnav_results.
    TYPES ty_tt_nationalidnav_results TYPE STANDARD TABLE OF ty_nationalidnav_results WITH NON-UNIQUE DEFAULT KEY.
    TYPES: BEGIN OF ty_nationalidnav,
             results TYPE ty_tt_nationalidnav_results,
           END OF ty_nationalidnav.
    TYPES: BEGIN OF ty_personnav,
             __metadata    TYPE ty_metadata,
             dateofbirth   TYPE string,
             nationalidnav TYPE ty_nationalidnav,
           END OF ty_personnav.


    TYPES: BEGIN OF ty_emplstatusnav,
             __metadata   TYPE ty_metadata,
             externalcode TYPE string,
           END OF ty_emplstatusnav.
    TYPES: BEGIN OF ty_usernav,
             __metadata  TYPE ty_metadata,
             empid       TYPE string,
             firstname   TYPE string,
             lastname    TYPE string,
             hiredate    TYPE string,
             displayname TYPE string,
             email       TYPE string,
             empinfo     TYPE ty_empinfo,
           END OF ty_usernav.
    TYPES: BEGIN OF ty_positionnav,
             __metadata         TYPE ty_metadata,
             externalname_tr_tr TYPE string,
             externalname_en_us TYPE string,
           END OF ty_positionnav.
    TYPES: BEGIN OF ty_locationnav,
             __metadata TYPE ty_metadata,
             name       TYPE string,
           END OF ty_locationnav.
    TYPES: BEGIN OF ty_employmentnav,
             __metadata TYPE ty_metadata,
             personnav  TYPE ty_personnav,
           END OF ty_employmentnav.
    TYPES: BEGIN OF ty_departmentnav,
             __metadata   TYPE ty_metadata,
             externalcode TYPE string,
             name         TYPE string,
           END OF ty_departmentnav.
    TYPES: BEGIN OF ty_companynav,
             __metadata   TYPE ty_metadata,
             externalcode TYPE string,
             name         TYPE string,
           END OF ty_companynav.


    TYPES: BEGIN OF ty_results,
             __metadata    TYPE ty_metadata,
             userid        TYPE string,
             managerid     TYPE string,
             emplstatusnav TYPE ty_emplstatusnav,
             usernav       TYPE ty_usernav,
             positionnav   TYPE ty_positionnav,
             locationnav   TYPE ty_locationnav,
             employmentnav TYPE ty_employmentnav,
             departmentnav TYPE ty_departmentnav,
             companynav    TYPE ty_companynav,
           END OF ty_results.
    TYPES ty_tt_results TYPE STANDARD TABLE OF ty_results WITH NON-UNIQUE DEFAULT KEY.
    TYPES: BEGIN OF ty_d,
             results TYPE ty_tt_results,
             __next  TYPE string,
           END OF ty_d.
    TYPES: BEGIN OF ty_user_data,
             d TYPE ty_d,
           END OF ty_user_data.


    DATA ls_json_data TYPE  ty_user_data.

    /ui2/cl_json=>deserialize( EXPORTING json             = lv_response
                                         pretty_name      = 'X'
                               CHANGING  data             = ls_json_data ).


    " fill internal table
    DATA: ls_user_data TYPE zab_get_user.

    LOOP AT ls_json_data-d-results INTO DATA(ls_result).
      ls_user_data-user_id    = ls_result-userid.
      ls_user_data-manager_id = ls_result-managerid.
      ls_user_data-status     = ls_result-emplstatusnav-externalcode.
      TRANSLATE ls_user_data-status TO UPPER CASE.
      ls_user_data-first_name = ls_result-usernav-firstname.
      ls_user_data-last_name  = ls_result-usernav-lastname.

      IF ls_result-usernav-empid IS NOT INITIAL.
        ls_user_data-pernr = ls_result-usernav-empid.
      ELSE.
        ls_user_data-pernr = ls_result-userid.
      ENDIF.

      SPLIT ls_result-usernav-hiredate AT '(' INTO DATA(dummy) DATA(jsondate).
      SPLIT jsondate AT ')' INTO jsondate dummy.

      cl_pco_utility=>convert_java_timestamp_to_abap(
        EXPORTING
          iv_timestamp = jsondate
        IMPORTING
          ev_date      = ls_user_data-hire_date
      ).

      ls_user_data-full_name  = ls_result-usernav-displayname.
      ls_user_data-email      = ls_result-usernav-email.

      ASSIGN ls_result-usernav-empinfo-personnav-phonenav-results[ 1 ] TO FIELD-SYMBOL(<ls_phonenumber>).
      IF <ls_phonenumber> IS ASSIGNED.
        ls_user_data-phonenumber_1 = <ls_phonenumber>-phonenumber.
        UNASSIGN <ls_phonenumber>.
      ENDIF.
      ASSIGN ls_result-usernav-empinfo-personnav-phonenav-results[ 2 ] TO <ls_phonenumber>.
      IF <ls_phonenumber> IS ASSIGNED.
        ls_user_data-phonenumber_2 = <ls_phonenumber>-phonenumber.
        UNASSIGN <ls_phonenumber>.
      ENDIF.
      ASSIGN ls_result-usernav-empinfo-personnav-phonenav-results[ 3 ] TO <ls_phonenumber>.
      IF <ls_phonenumber> IS ASSIGNED.
        ls_user_data-phonenumber_3 = <ls_phonenumber>-phonenumber.
        UNASSIGN <ls_phonenumber>.
      ENDIF.

      ls_user_data-position_name_tr = ls_result-positionnav-externalname_tr_tr.
      ls_user_data-position_name_en = ls_result-positionnav-externalname_en_us.
      ls_user_data-location         = ls_result-locationnav-name.

      SPLIT ls_result-employmentnav-personnav-dateofbirth AT '(' INTO dummy jsondate.
      SPLIT jsondate AT ')' INTO jsondate dummy.

      cl_pco_utility=>convert_java_timestamp_to_abap(
        EXPORTING
          iv_timestamp = jsondate
        IMPORTING
          ev_date      = ls_user_data-date_of_birth
      ).


      ASSIGN ls_result-employmentnav-personnav-nationalidnav-results[ 1 ] TO FIELD-SYMBOL(<ls_nationalid>).
      IF <ls_nationalid> IS ASSIGNED.
        ls_user_data-national_id = <ls_nationalid>-nationalid.
        UNASSIGN <ls_nationalid>.
      ENDIF.

      ls_user_data-department_code = ls_result-departmentnav-externalcode.
      ls_user_data-department_name = ls_result-departmentnav-name.
      ls_user_data-company_code    = ls_result-companynav-externalcode.
      ls_user_data-company_name    = ls_result-companynav-name.

      APPEND ls_user_data TO gt_sf_data.
      CLEAR: ls_user_data.
    ENDLOOP.


    IF ls_json_data-d-__next IS NOT INITIAL.
      zab_get_data_sf_user=>get_sf_data( ).
    ENDIF.


  ENDMETHOD.

  METHOD get_sap_data.

    DATA: it_fields TYPE STANDARD TABLE OF rfc_db_fld.   " Namen der Spalten
    DATA: it_options TYPE STANDARD TABLE OF rfc_db_opt.
    it_options = VALUE #( ( |ENDDA >= '{ sy-datum }' AND BEGDA <= '{ sy-datum }'| ) ).
* Spalten
*it_fields = VALUE #( ( fieldname = 'PERNR' )
*                     ( fieldname = 'STAT2' ) ).
*#  1- PA0000 Tablosu

    CALL FUNCTION 'RFC_READ_TABLE' DESTINATION 'PS4CLNT100'
      EXPORTING
        query_table          = 'PA0000'               " Table read
*       delimiter            = space            " Sign for indicating field limits in DATA
*       no_data              = space            " If <> SPACE, only FIELDS is filled
*       rowskips             = 0
*       rowcount             = 0
*       get_sorted           =
*       use_et_data_4_return =
*  IMPORTING
*       et_data              =
      TABLES
        options              = it_options            " Selection entries, "WHERE clauses" (in)
*       fields               = it_fields               " Names (in) and structure (out) of fields read
        data                 = lt_sap_data_0000                 " Data read (out)
      EXCEPTIONS
        table_not_available  = 1                " QUERY_TABLE not active in Dictionary
        table_without_data   = 2                " QUERY_TABLE is name of structure
        option_not_valid     = 3                " Selection entries (e.g. syntax) incorrect
        field_not_valid      = 4                " Field to be read not in table
        not_authorized       = 5                " User not authorized to access QUERY_TABLE
        data_buffer_exceeded = 6                " Selected fields do not fit into structure DATA
        OTHERS               = 7.
    IF sy-subrc <> 0.
* MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
*   WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
    ENDIF.


*#  2- PA0001 Tablosu

    CALL FUNCTION 'RFC_READ_TABLE' DESTINATION 'PS4CLNT100'
      EXPORTING
        query_table          = 'PA0001'               " Table read
*       delimiter            = space            " Sign for indicating field limits in DATA
*       no_data              = space            " If <> SPACE, only FIELDS is filled
*       rowskips             = 0
*       rowcount             = 0
*       get_sorted           =
*       use_et_data_4_return =
*  IMPORTING
*       et_data              =
      TABLES
        options              = it_options            " Selection entries, "WHERE clauses" (in)
*       fields               = it_fields               " Names (in) and structure (out) of fields read
        data                 = lt_sap_data_0001                 " Data read (out)
      EXCEPTIONS
        table_not_available  = 1                " QUERY_TABLE not active in Dictionary
        table_without_data   = 2                " QUERY_TABLE is name of structure
        option_not_valid     = 3                " Selection entries (e.g. syntax) incorrect
        field_not_valid      = 4                " Field to be read not in table
        not_authorized       = 5                " User not authorized to access QUERY_TABLE
        data_buffer_exceeded = 6                " Selected fields do not fit into structure DATA
        OTHERS               = 7.
    IF sy-subrc <> 0.
* MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
*   WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
    ENDIF.



*#  3- PA0002 Tablosu

    CALL FUNCTION 'RFC_READ_TABLE' DESTINATION 'PS4CLNT100'
      EXPORTING
        query_table          = 'PA0002'               " Table read
*       delimiter            = space            " Sign for indicating field limits in DATA
*       no_data              = space            " If <> SPACE, only FIELDS is filled
*       rowskips             = 0
*       rowcount             = 0
*       get_sorted           =
*       use_et_data_4_return =
*  IMPORTING
*       et_data              =
      TABLES
        options              = it_options            " Selection entries, "WHERE clauses" (in)
*       fields               = it_fields               " Names (in) and structure (out) of fields read
        data                 = lt_sap_data_0002                 " Data read (out)
      EXCEPTIONS
        table_not_available  = 1                " QUERY_TABLE not active in Dictionary
        table_without_data   = 2                " QUERY_TABLE is name of structure
        option_not_valid     = 3                " Selection entries (e.g. syntax) incorrect
        field_not_valid      = 4                " Field to be read not in table
        not_authorized       = 5                " User not authorized to access QUERY_TABLE
        data_buffer_exceeded = 6                " Selected fields do not fit into structure DATA
        OTHERS               = 7.
    IF sy-subrc <> 0.
* MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
*   WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
    ENDIF.

  ENDMETHOD.

  METHOD compare_data.

    TYPES: BEGIN OF ty_hr_data,
             pernr TYPE pa0000-pernr, " PERNR tipi PA0000 tablosundan alınır
             stat2 TYPE pa0000-stat2, " STAT2 tipi PA0000 tablosundan alınır
           END OF ty_hr_data.

    DATA: ls_missing   TYPE zab_get_user.



*lt_sap_data_0001 : SAP Canli daki tablo verileri   1 Bilgi tipine ait veriler
*lt_sap_data_0002 : SAP Canli daki tablo verileri   2 Bilgi Tipine ait veriler



* 2. SF ve HR verilerini karşılaştır

    LOOP AT gt_sf_data INTO DATA(ls_sf_data).
      READ TABLE lt_sap_data_0000 INTO DATA(ls_sap_data)
        WITH KEY pernr = ls_sf_data-pernr. " PERNR ile karşılaştır

      IF sy-subrc <> 0.
        APPEND ls_sf_data TO lt_sap_missing.

        APPEND VALUE #( pernr = ls_sf_data-pernr system = 'SF' ) TO lt_missing.
      ELSEIF ( ls_sf_data-status = 'A'   AND  ls_sap_data-stat2 <> 3 ) OR
             ( ls_sf_data-status <> 'A'  AND  ls_sap_data-stat2 = 3 ).
        " Farklılıkları yeni tabloya ekle
        APPEND ls_sf_data TO gt_status_diff.


      ENDIF.
    ENDLOOP.


    LOOP AT lt_sap_data_0000 INTO ls_sap_data.
      READ TABLE gt_sf_data INTO ls_sf_data
        WITH KEY pernr = ls_sap_data-pernr. " PERNR ile karşılaştır

      IF sy-subrc <> 0.
        ls_missing-pernr = ls_sap_data-pernr.
        APPEND ls_missing TO lt_sf_missing.

        APPEND VALUE #( pernr = ls_missing-pernr system = 'SAP' ) TO lt_missing.

        CLEAR: ls_missing.
      ENDIF.
    ENDLOOP.

    gt_status_diff_sum = CORRESPONDING #( gt_status_diff MAPPING pernr = pernr
                                                                 sf    = status  ).

    LOOP AT gt_status_diff_sum  ASSIGNING FIELD-SYMBOL(<ls_status_diff>).
      <ls_status_diff>-sap = SWITCH #( <ls_status_diff>-sf WHEN 'A' THEN 'T'
                                                           WHEN 'T' THEN 'A' ).
    ENDLOOP.

  ENDMETHOD.

  METHOD display_alv.

    DATA:lv_count_sap TYPE i,
         lv_count_sf  TYPE i.


    ls_alv-xyz  = 'Toplam Personel'.
    ls_alv-sap  = lines( lt_sap_data_0000 ).
    ls_alv-sf   = lines( gt_sf_data ).
    ls_alv-diff = lines( lt_sap_missing ) + lines( lt_sf_missing ).
    APPEND ls_alv TO lt_alv.
    CLEAR: ls_alv.


    CLEAR lv_count_sap.
    LOOP AT lt_sap_data_0000 TRANSPORTING NO FIELDS WHERE stat2 = 3.
      lv_count_sap = lv_count_sap + 1.
    ENDLOOP.
    CLEAR lv_count_sf.
    LOOP AT gt_sf_data TRANSPORTING NO FIELDS WHERE status = 'A'.
      lv_count_sf = lv_count_sf + 1.
    ENDLOOP.

    ls_alv-xyz  = 'Aktif Personel'.
    ls_alv-sap  = lv_count_sap.
    ls_alv-sf   = lv_count_sf.
    ls_alv-diff = lines( gt_status_diff ).
    APPEND ls_alv TO lt_alv.
    CLEAR: ls_alv.


    CLEAR lv_count_sap.
    LOOP AT lt_sap_data_0000 TRANSPORTING NO FIELDS WHERE stat2 <> 3.
      lv_count_sap = lv_count_sap + 1.
    ENDLOOP.
    CLEAR lv_count_sf.
    LOOP AT gt_sf_data TRANSPORTING NO FIELDS WHERE status <> 'A'.
      lv_count_sf = lv_count_sf + 1.
    ENDLOOP.

    ls_alv-xyz  = 'Pasif Personel'.
    ls_alv-sap  = lv_count_sap.
    ls_alv-sf   = lv_count_sf.
    ls_alv-diff = lines( gt_status_diff ).
    APPEND ls_alv TO lt_alv.
    CLEAR: ls_alv.


    TRY.
        CALL METHOD cl_salv_table=>factory
          IMPORTING
            r_salv_table = DATA(go_salv)
          CHANGING
            t_table      = lt_alv.

      CATCH cx_salv_msg.
        RETURN.
    ENDTRY.


    DATA go_column TYPE REF TO cl_salv_column_table.
    DATA: gr_display   TYPE REF TO cl_salv_display_settings.
    DATA(go_columns) = go_salv->get_columns( ).

*  go_columns->set_optimize( ).



    go_salv->get_functions( )->set_all( abap_true ).

    gr_display = go_salv->get_display_settings( ).
    gr_display->set_list_header( 'SAP ve SF Sistemi Genel Fark Raporu' ).


    TRY.
        go_columns->get_column( 'XYZ'  )->set_short_text( '' ).
        go_columns->get_column( 'XYZ'  )->set_output_length( 20 ).
        go_columns->get_column( 'SAP'  )->set_short_text( 'SAP' ).
        go_columns->get_column( 'SAP'  )->set_output_length( 20 ).
        go_columns->get_column( 'SF'   )->set_short_text( 'SF' ).
        go_columns->get_column( 'SF'   )->set_output_length( 20 ).
        go_columns->get_column( 'DIFF' )->set_short_text( 'Farklı' ).
        go_columns->get_column( 'DIFF' )->set_output_length( 20 ).

      CATCH cx_salv_not_found.
    ENDTRY.


*    TRY.
*        go_column ?= go_columns->get_column( 'SAP' ).
*        go_column->set_cell_type( if_salv_c_cell_type=>hotspot ).
*
*      CATCH cx_salv_not_found.
*    ENDTRY.
    TRY.
        go_column ?= go_columns->get_column( 'SF' ).
        go_column->set_cell_type( if_salv_c_cell_type=>hotspot ).

      CATCH cx_salv_not_found.
    ENDTRY.
    TRY.
        go_column ?= go_columns->get_column( 'DIFF' ).
        go_column->set_cell_type( if_salv_c_cell_type=>hotspot ).

      CATCH cx_salv_not_found.
    ENDTRY.


    " Event handler oluştur ve bağla
    DATA: lo_event_handler TYPE REF TO lcl_events.
    CREATE OBJECT lo_event_handler.

    SET HANDLER lcl_events=>on_link_click FOR go_salv->get_event( ).


    go_salv->display( ).

  ENDMETHOD.

  METHOD get_user_data.
    rt_user_data = gt_sf_data. " Global tabloyu döndür
  ENDMETHOD.

  METHOD create_http_client.
    TRY.
        cl_http_client=>create_by_url(
          EXPORTING
            url    = url
          IMPORTING
            client = client ).
      CATCH cx_http_ext_exception INTO DATA(lx_client_error).
        MESSAGE lx_client_error->get_text( ) TYPE 'E'.
    ENDTRY.
  ENDMETHOD.

  METHOD prepare_request.
    DATA: lt_http TYPE tihttpnvp.

    " Header bilgilerini ayarla
    lt_http = VALUE #(
      ( name = 'Authorization' value = auth_token )
      ( name = 'Content-Type'  value = content_type ) ).

    client->request->set_method( 'GET' ).
    client->request->set_version( if_http_request=>co_protocol_version_1_1 ).
    client->request->set_header_fields( fields = lt_http ).
    client->request->set_content_type( content_type ). " Content-Type dışarıdan gelen değerle ayarlanır
    client->request->set_header_field(
      name  = 'accept'                " Name of the header field
      value = 'application/json'                " HTTP header field value
    ).
  ENDMETHOD.

  METHOD send_request.
    TRY.
        client->send( ).
        client->receive( ).
        response = client->response->get_cdata( ).

      CATCH cx_http_ext_exception INTO DATA(lx_proc_error).
        MESSAGE lx_proc_error->get_text( ) TYPE 'E'.
    ENDTRY.
  ENDMETHOD.

  METHOD log_response.
*    WRITE: "/ 'Response:', response,
*           / 'Api status:', status.
*    " Debugging için bırakıldı
  ENDMETHOD.


ENDCLASS.
