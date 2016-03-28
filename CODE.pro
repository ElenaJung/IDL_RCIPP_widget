PRO RCIPP_event, ev


WIDGET_CONTROL, ev.TOP, GET_UVALUE=drawid
WIDGET_CONTROL, ev.ID, GET_UVALUE=uval, /CONTEXT_EVENTS

COMMON block_names, second_base, third_base, fourth_base, fifth_base, sixth_base, seventh_base, eighth_base,  ninth_base, tenth_base, eleventh_base, draw_generate,  draw_histoplot, drawroigraph, draw, drawoffset, drawloadpds, drawloadpds_2, drawcie, drawexp_1, drawexp_2, drawexp_3, drawexp_4, file, mistake, Stereo, bgroup2, myoutfile, myoutdir, savefile, number_of_files_stats, filter_number, y_reflectance, stat_test, radiance_per_sec, Rstar_check, minimum, maximum, spline_array, X, Y, Z, little_x, little_y, mistake2, mistake3, file2, roi_test, file4, rstar_spline_test, CIE_test, CIE_little_xyz_test, directory, count_slp_2, count_slp_1, count_exp, mistake6, mistake5, mistake4, file_R, file_E, aupe_check, mistake7, file3, file5, x_filters_R, y_reflectance_R, y_standard_deviation_R, x_filters, y_standard_deviation, number_of_files, L_or_R, myoutfile_O, count_L, count_R, savefile_RWAC, img_dir, mistake_gen, mistake_srgb, n, white_data, neutral_44_data, neutral_70_data, neutral_1_05_data, black_data, blue_data, green_data, red_data, yellow_data, white, neutral_44, neutral_70, neutral_1_05, black, blue, green, red, yellow, colour_array
CASE uval OF 

  'Co_register_images' : BEGIN
  Message = DIALOG_MESSAGE("This is a dummy button",/INFORMATION)
  END
  
  'Flat_Field_correction' : BEGIN
  Message = DIALOG_MESSAGE("This is a dummy button",/INFORMATION)
  END
  
  'Camera_response_correction' : BEGIN
  Message = DIALOG_MESSAGE("This is a dummy button",/INFORMATION)
  END
  
  'Generate_RGB_image' : BEGIN
  
  ; below a dialogue file is opened which allows the user to select one or three image files
  ; with which a grey scale or RGB colour image will be displayed and saved
  
  path_in = !DIR+'/examples/data'
  file = DIALOG_PICKFILE(PATH=path_in, /MULTIPLE_FILES, /READ, $
  FILTER='*.png', /FIX_FILTER)
  
  ; Check to see if one or more files were 
  
  IF (file[0] NE '') THEN BEGIN
  
  ; Rstar_check is the variable which tells the program whether it is looking at AUPE or PDS data. 
  ; Rstar_check = 0 for AUPE data and rstar_check = 1 for PDS data
  
  Rstar_check = 0
  
  ; Set the current graphics window to the one with the drawid (this is the main graphics window on the widget on the widget)
  ; and erase anything that was previously there
  
  WSET, drawid
  ERASE
  
  ; Only allow one or three image files past this point
  
    IF (SIZE(file, /N_ELEMENTS) EQ 3 OR SIZE(file, /N_ELEMENTS) EQ 1) THEN BEGIN
  
  ; The mistake variables are all used in the various sub-widgets. They are needed because the subwidgets can currently only
  ; be opened once, otherwise an error occurs. In order to catch the error, the mistake variable gets changed to 1 in the
  ; sub-widget function and an IF statement at the beginning of the sub-widget function only lets the program continue if
  ; the error is equal to 0
  
    mistake = 0
    mistake4 = 0
    mistake5 = 0
    mistake6 = 0
    mistake7 = 0
  
  ; aupe_check lets the program know if the data is AUPE or PDS 
  
    aupe_check = 1
  
  ; This section finds the last '\' in the directory name and then cuts out the the directpry from the beginning to the '\', this
  ; is then called myoutdir (e.g. directory is C:/users/user/Desktop/image.png, changes to C:/users/user/Desktop/)
  
    dir_length = strpos(file[0], '\', /reverse_search)
    myoutdir = strmid(file[0], 0, dir_length + 1)
  
  ; As the image files need to be in a folder named either LWAC or RWAC (depending on which camera they are from), the LWAC or RWAC
  ; string can be cut out in order to decipher  from which camera the images have been taken, this is needed further down in the program.
  ; the variable L_or_R_dir is the myoutfile minus the RWAC/LWAC, and L_or_R dir contains the string LWAC or RWAC
  
    L_or_R_cut = strmid(file[0], 0, dir_length)
    L_or_R_length = strpos(L_or_R_cut, '\', /reverse_search)
    L_or_R = strmid(myoutdir, L_or_R_length + 1, 4)
    L_or_R_dir = strmid(myoutdir, 0, L_or_R_length + 1)
    IF L_or_R EQ 'LWAC' or L_or_R EQ 'RWAC' THEN BEGIN
    count_L = ''
    count_R = ''
    IF L_or_R EQ 'LWAC' THEN BEGIN
    L_or_R_dir = L_or_R_dir + 'RWAC'
    print, 'L_or_R_dir = ', L_or_R_dir
  
  ; If the images were taken from the LWAC, then a filesearch gets done for the directory L_or_R_dir + RWAC. The filesearch counts how often
  ; the string was found and places it in the variable count_R. The same is done vice versa using count_L
  
    search = file_search(L_or_R_dir, count = count_R)
    print, 'count_R = ', count_R
    ENDIF
    IF L_or_R EQ 'RWAC' THEN BEGIN
    L_or_R_dir = L_or_R_dir + 'LWAC'
    print, 'L_or_R_dir = ', L_or_R_dir
    search = file_search(L_or_R_dir, count = count_L)
    print, 'count_L = ', count_L
    ENDIF    
  
  ; The progress bar is started
  
    progressBar = Obj_New("SHOWPROGRESS")
    progressBar->Start
  
  ; A filesearch is done for the files shown below and the count is placed in variables. These will be needed for the creation of RStar files
  ; later in the program
  
    myoutdir_exp = myoutdir + 'all_exposure.dat'
    myoutdir_slp_1 = myoutdir + 'radiometric_scaling_factor_wavelength_438.dat'
    myoutdir_slp_2 = myoutdir + 'radiometric_scaling_factor_wavelength_740.dat'
    search_exp = file_search(myoutdir_exp, count = count_exp)
    search_slp_1 = file_search(myoutdir_slp_1, count = count_slp_1)
    search_slp_2 = file_search(myoutdir_slp_2, count = count_slp_2)        
  
    ;To display the image correctly, then it needs to be scaled according to its image size.
    ;The image header is read to get the x and y pixels values.
    ;The following IF statements calculated the final x and y pixel values for the display
    ;window. CONGRID performs the scaling if required
  
    imSize = SIZE(read_png(file[0]), /DIMENSION)
    x_pixels = imSize[0]
    y_pixels = imSize[1]
  
    thecount = 0
  
      IF x_pixels EQ y_pixels THEN BEGIN
      x_val = 450
      y_val = 450    
      ENDIF
      IF x_pixels GT y_pixels THEN BEGIN
      WIDGET_CONTROL,draw, DRAW_XSIZE = 450, DRAW_YSIZE = FIX((FLOAT(y_pixels)/FLOAT(x_pixels)) * 450)
      x_val = 450
      y_val = FIX((FLOAT(y_pixels)/FLOAT(x_pixels)) * 450)
      ENDIF
      IF x_pixels LT y_pixels THEN BEGIN
      WIDGET_CONTROL, draw, DRAW_XSIZE = FIX((FLOAT(x_pixels)/FLOAT(y_pixels)) * 450), DRAW_YSIZE = 450
      x_val = FIX((FLOAT(x_pixels)/FLOAT(y_pixels)) * 450)
      y_val = 450
      ENDIF
    
      IF (SIZE(file, /N_ELEMENTS) EQ 3) THEN BEGIN
    
    ; The images are read into the following variables:
     
      myimg_0 = read_png(file[0]) 
      myimg_1 = read_png(file[1]) 
      myimg_2 = read_png(file[2])
    
    ; Below, the images (which have the same file names as those above) from the other camera are also read and placed into variables.
    ; For example, if the images f1.png, f2.png and f3.png from LWAC were read above, then f1.png, f2.png and f3.png will be read from RWAC   
      
      IF count_R NE '' OR count_L NE '' THEN BEGIN
      R_length = strpos(file[0], '\', /reverse_search)
      file_name_0 = strmid(file[0], R_length + 1)
      file_name_1 = strmid(file[1], R_length + 1)
      file_name_2 = strmid(file[2], R_length + 1)
      print, 'file_name_2 = ', file_name_2
      file0 = L_or_R_dir + '\' + file_name_0
      file1 = L_or_R_dir + '\' + file_name_1
      file2 = L_or_R_dir + '\' + file_name_2
      print, 'file2 = ', file2
      myimg_0_O = read_png(file0) 
      myimg_1_O = read_png(file1) 
      myimg_2_O = read_png(file2)
      ENDIF
        
     
      s=size(myimg_0,/dimension)
      RGB=intarr(3,s[0],s[1])
    
    ; Used in 'save_image' event below:
    
      New_RGB=fltarr(3,s[0],s[1]) 
    
    ; Used in this IF statement:
    
      scaled_RGB=intarr(3,x_val,y_val) 
    
    ; The same as above is done for LWAC/RWAC (whichever the original images did not come from)
    
      IF count_R NE '' OR count_L NE '' THEN BEGIN
      RGB_O=intarr(3,s[0],s[1])
      O_New_RGB=fltarr(3,s[0],s[1])
      RGB_O[0,*,*]= myimg_0_O
      RGB_O[1,*,*]= myimg_1_O
      RGB_O[2,*,*]= myimg_2_O      
      ENDIF
    
   ; The images are placed together to create an RGB image, then scaled down and then displayed in the graphics window
  
      RGB[0,*,*]= myimg_0
      RGB[1,*,*]= myimg_1
      RGB[2,*,*]= myimg_2
      scaled_RGB[2,*,*] = congrid(myimg_0, x_val, y_val, /center)
      scaled_RGB[1,*,*] = congrid(myimg_1, x_val, y_val, /center)
      scaled_RGB[0,*,*] = congrid(myimg_2, x_val, y_val, /center)
      dir_length = strpos(file[0], '\', /reverse_search)
      myoutdir = strmid(file[0], 0, dir_length + 1)
      TVSCL, scaled_RGB, true=1
    
      ; The following string manipulation functions extract which filtered images have been selected,
      ; and create a filename with these values. (Lots of IF statements to cope with all the variations)
    
      length_all = make_array(1, 3, /INTEGER)
      length0 = strlen(file[0])
      length1 = strlen(file[1])
      length2 = strlen(file[2])
      length_all [0] = length0
      length_all [1] = length1
      length_all [2] = length2
      max_length = max(length_all)
        IF (max_length EQ (dir_length + 8) OR max_length EQ (dir_length + 7)) THEN BEGIN
          IF (max_length EQ (dir_length + 8)) THEN BEGIN
            IF length0 EQ max_length THEN BEGIN
            filter_no_1 = strmid(file[0], (max_length - 7), 3)
            ENDIF ELSE BEGIN
            filter_no_1 = strmid(file[0], (max_length - 7), 2)
            ENDELSE
            IF length1 EQ max_length THEN BEGIN
            filter_no_2 = strmid(file[1], (max_length - 7), 3)
            ENDIF ELSE BEGIN
            filter_no_2 = strmid(file[1], (max_length - 7), 2)
            ENDELSE
            IF length2 EQ max_length THEN BEGIN
            filter_no_3 = strmid(file[2], (max_length - 7), 3)
            ENDIF ELSE BEGIN
            filter_no_3 = strmid(file[2], (max_length - 7), 2)
            ENDELSE
            ENDIF
            IF (max_length EQ (dir_length + 7)) THEN BEGIN
            filter_no_1 = strmid(file[0], (max_length - 6), 2)
            filter_no_2 = strmid(file[1], (max_length - 6), 2)
            filter_no_3 = strmid(file[2], (max_length - 6), 2)  
            ENDIF 

      progressBar->Update, (1)*50
    
            IF (max_length EQ (dir_length + 8)) THEN BEGIN
              IF length0 EQ length1 AND length1 EQ length2 THEN BEGIN
              myoutfile = 'RGB-   -   -   .png'
              strput, myoutfile, filter_no_1, 4
              strput, myoutfile, filter_no_2, 8
              strput, myoutfile, filter_no_3, 12
              ENDIF
              IF length0 GT length1 AND length0 GT length2 THEN BEGIN
              myoutfile = 'RGB-   -  -  .png'
              strput, myoutfile, filter_no_1, 4
              strput, myoutfile, filter_no_2, 8
              strput, myoutfile, filter_no_3, 11
              ENDIF
              IF length1 GT length0 AND length1 GT length2 THEN BEGIN
              myoutfile = 'RGB-  -   -  .png'
              strput, myoutfile, filter_no_1, 4
              strput, myoutfile, filter_no_2, 7
              strput, myoutfile, filter_no_3, 11
              ENDIF
              IF length2 GT length0 AND length2 GT length1 THEN BEGIN
              myoutfile = 'RGB-  -  -   .png'
              strput, myoutfile, filter_no_1, 4
              strput, myoutfile, filter_no_2, 7
              strput, myoutfile, filter_no_3, 10
              ENDIF
              IF length0 EQ length1 AND length0 GT length2 THEN BEGIN
              myoutfile = 'RGB-   -   -  .png'
              strput, myoutfile, filter_no_1, 4
              strput, myoutfile, filter_no_2, 8
              strput, myoutfile, filter_no_3, 12    
              ENDIF
              IF length1 EQ length2 AND length1 GT length0 THEN BEGIN
              myoutfile = 'RGB-  -   -   .png'
              strput, myoutfile, filter_no_1, 4
              strput, myoutfile, filter_no_2, 7
              strput, myoutfile, filter_no_3, 11
              ENDIF
              IF length0 EQ length2 AND length0 GT length1 THEN BEGIN
              myoutfile = 'RGB-   -  -   .png'
              strput, myoutfile, filter_no_1, 4
              strput, myoutfile, filter_no_2, 8
              strput, myoutfile, filter_no_3, 11
              ENDIF
            ENDIF
              IF (max_length EQ (dir_length + 7)) THEN BEGIN
              myoutfile = 'RGB-  -  -  .png'
              strput, myoutfile, filter_no_1, 4
              strput, myoutfile, filter_no_2, 7
              strput, myoutfile, filter_no_3, 10
              ENDIF
          dir_length = strpos(file[0], '\', /reverse_search)
          myoutdir = strmid(file[0], 0, dir_length + 1)
          myoutfile = myoutdir + myoutfile
      
          ; Scale the RGB image data from 16-bit to 8-bit. This can be read by the XROI widget.
      
          New_RGB[2,*,*] = (!D.table_size - 1)* (FLOAT(RGB[0,*,*] - min(RGB[0,*,*]))/FLOAT(max(RGB[0,*,*]) - min(RGB[0,*,*])))
          New_RGB[1,*,*] = (!D.table_size - 1)* (FLOAT(RGB[1,*,*] - min(RGB[1,*,*]))/FLOAT(max(RGB[1,*,*]) - min(RGB[1,*,*])))
          New_RGB[0,*,*] = (!D.table_size - 1)* (FLOAT(RGB[2,*,*] - min(RGB[2,*,*]))/FLOAT(max(RGB[2,*,*]) - min(RGB[2,*,*])))
      
      ; Scale the RGB image data from 16-bit to 8-bit for the other camera (e.g. LWAC or RWAC).
          
          IF count_R NE '' OR count_L NE '' THEN BEGIN
          O_New_RGB[2,*,*] = (!D.table_size - 1)* (FLOAT(RGB_O[0,*,*] - min(RGB_O[0,*,*]))/FLOAT(max(RGB_O[0,*,*]) - min(RGB_O[0,*,*])))
          O_New_RGB[1,*,*] = (!D.table_size - 1)* (FLOAT(RGB_O[1,*,*] - min(RGB_O[1,*,*]))/FLOAT(max(RGB_O[1,*,*]) - min(RGB_O[1,*,*])))
          O_New_RGB[0,*,*] = (!D.table_size - 1)* (FLOAT(RGB_O[2,*,*] - min(RGB_O[2,*,*]))/FLOAT(max(RGB_O[2,*,*]) - min(RGB_O[2,*,*])))
          ENDIF
          
      ; Create and save a png image file with the filename created above and the 8-bit RGB colour values just created
      
          write_png, myoutfile, new_RGB
          print, 'myoutfile = ', myoutfile
          
      ; Create and save a png image file with the filename created above and the 8-bit RGB colour values just created for the other camera
      ; e.g. LWAC or RWAC
      
          IF count_R NE '' OR count_L NE '' THEN BEGIN
          R_length = strpos(myoutfile, '\', /reverse_search)
          file_name_O = strmid(myoutfile, R_length + 1)
          print, 'file_name_O = ', file_name_O
          myoutfile_O = L_or_R_dir + '\' + file_name_O
          print, 'myoutfile_O = ', myoutfile_O
          write_png, myoutfile_O, O_new_RGB
          ENDIF
          
          ENDIF ELSE BEGIN
          message = DIALOG_MESSAGE("THIS IMAGE HAS NOT BEEN SAVED. Please make sure that your images follow the naming convention of 'f1.png', 'f2.png', etc and that no image name is greater than f99", /INFORMATION)
          ENDELSE
        ENDIF
    
    ; Below a similar procedure is followed if just one image file was selected with the pickfile. This produces a black and white image
    
          IF (SIZE(file, /N_ELEMENTS) EQ 1) THEN BEGIN
          myimg_0 = read_png(file[0]) ; /silent) ;/noscale)
          dir_length = strpos(file[0], '\', /reverse_search)
          myoutdir = strmid(file[0], 0, dir_length + 1)
          
      IF count_R NE '' OR count_L NE '' THEN BEGIN
      R_length = strpos(file[0], '\', /reverse_search)
      file_name_0 = strmid(file[0], R_length + 1)
      print, 'file_name_0 = ', file_name_0
      file0 = L_or_R_dir + '\' + file_name_0
      print, 'file0 = ', file0
      myimg_0_O = read_png(file0) 
      ENDIF
          
          TVSCL, congrid(myimg_0, x_val, y_val, /center)
          length = strlen(file[0])
          s1=size(file,/dimension)
      
          ;Create a new string array for the output file path and assign 'myinfile'.

          lengthdir = strlen(myoutdir)
 
          myoutfile = strarr(1)       
          myoutfile[*] = file[0]
          lengthfile = strlen(myoutfile)
          

          diff_length = lengthfile - lengthdir

     progressBar->Update, (1)*50
   
            IF (diff_length EQ 6) OR (diff_length EQ 7) THEN BEGIN
              IF (diff_length EQ 6) THEN BEGIN
              filter_number = strmid(myoutfile, lengthdir, 6)
              myoutfilenew = myoutdir + 'B+W_' + filter_number
              scaled_image = (!D.table_size - 1)* (FLOAT(myimg_0 - min(myimg_0))/FLOAT(max(myimg_0) - min(myimg_0)))
              write_png, myoutfilenew, scaled_image
              ENDIF
              IF (diff_length EQ 7) THEN BEGIN
              filter_number = strmid(myoutfile, lengthdir, 7)
              myoutfilenew = myoutdir + 'B+W_' + filter_number
              scaled_image = (!D.table_size - 1)* (FLOAT(myimg_0 - min(myimg_0))/FLOAT(max(myimg_0) - min(myimg_0)))
              write_png, myoutfilenew, scaled_image
              ENDIF
              
              IF count_R NE '' OR count_L NE '' THEN BEGIN
              scaled_image_O = (!D.table_size - 1)* (FLOAT(myimg_0_O - min(myimg_0_O))/FLOAT(max(myimg_0_O) - min(myimg_0_O)))
              
              myoutfile_O = L_or_R_dir + '\' + 'B+W_' + filter_number
              print, 'myoutfile_O = ', myoutfile_O
                
              write_png, myoutfile_O, scaled_image_O
              ENDIF
              
              
            ENDIF ELSE BEGIN
            message = DIALOG_MESSAGE("THIS IMAGE HAS NOT BEEN SAVED. Please make sure that your images follow the naming convention of 'f1.png', 'f2.png', etc and that no image name is greater than f99", /INFORMATION)
            ENDELSE
          ENDIF
          progressBar->Destroy
          Obj_Destroy, progressBar
          ENDIF ELSE BEGIN
      Message = DIALOG_MESSAGE("Please make sure that your folders are labled 'LWAC' and/or 'RWAC'",/INFORMATION)
    ENDELSE  
        ENDIF
        IF (SIZE(file, /N_ELEMENTS) NE 3 AND SIZE(file, /N_ELEMENTS) NE 1) THEN BEGIN
        Message = DIALOG_MESSAGE("SELECT 1 AUPE2 FILE, OR 3 AUPE2 FILES",/INFORMATION)
        ENDIF
      ENDIF ELSE BEGIN
      Message = DIALOG_MESSAGE("NO AUPE2 DATA SELECTED",/INFORMATION)
    ENDELSE
  END
  
  'Calculate_offset_and_slope' : BEGIN

  ; This section creates the sub-widget which allows the offset and slope to be calculated for AUPE data
   
    IF (file[0] NE '') THEN BEGIN
      IF (mistake EQ 0) THEN BEGIN
      WIDGET_CONTROL, second_base, /REALIZE
      WIDGET_CONTROL, drawoffset, GET_VALUE=drawoffsetid
      WIDGET_CONTROL, second_base, SET_UVALUE=drawoffsetid
      WSET, drawoffsetid

    ; The section below loads the title image for the sub-widget
      
      CD, C=c
      IF c NE img_dir THEN BEGIN
      ENDIF
      restore, 'titlesecondbase.sav'
      TVSCL, image9, true=1
      mistake = 1

ENDIF
      
      ENDIF ELSE BEGIN
      
      message = DIALOG_MESSAGE("Currently this button cannot be pressed twice due to a bug in the program :( please restart if you need to use this button", /INFORMATION)
      ENDELSE
    ENDIF ELSE BEGIN
    Message = DIALOG_MESSAGE("PLEASE SELECT AUPE2 DATA",/INFORMATION)
    ENDELSE
  END
  
  'Load_PDS_data' : BEGIN
  
  path_in = !DIR+'/examples/data'
  file = DIALOG_PICKFILE(PATH=path_in, /MULTIPLE_FILES, /READ, $
  FILTER='*.img', /FIX_FILTER)
  
; Use IF statement to make sure that returned 'file' is not empty.

    IF (file[0] NE '') THEN BEGIN
  
  ; The variables are set so that they don't interfere with the AUPE data
  
    count_slp_1 = 1
    count_slp_2 = 1
    count_exp = 1
    Rstar_check = 1
    aupe_check = 2
  
    WSET, drawid
    ERASE
      IF (SIZE(file, /N_ELEMENTS) EQ 3 OR SIZE(file, /N_ELEMENTS) EQ 1) THEN BEGIN
      progressBar = Obj_New("SHOWPROGRESS")
      progressBar->Start
    
      ;To display the image correctly, then it needs to be scaled according to its image size.
      ;The image header is read to get the x and y pixels values.
      ;The following IF statements calculated the final x and y pixel values for the display
      ;window. CONGRID performs the scaling if required.
   
      CD, !dir
      label = headpds(file[0],/silent)
      line_samples = pdspar(label, 'LINE_SAMPLES')
      x_pixels = FIX(line_samples[1])
      lines = pdspar(label, 'LINES')
      y_pixels = FIX(lines[1])
        IF x_pixels EQ y_pixels THEN BEGIN
        x_val = 450
        y_val = 450
        ENDIF
        IF x_pixels GT y_pixels THEN BEGIN
        x_val = 450
        y_val = FIX((FLOAT(y_pixels)/FLOAT(x_pixels)) * 450)
        ENDIF
        IF x_pixels LT y_pixels THEN BEGIN
        x_val = FIX((FLOAT(x_pixels)/FLOAT(y_pixels)) * 450)
        y_val = 450
        ENDIF
    
    ; A RGB image is created, scaled and then displayed in the graphics window
  
        IF (SIZE(file, /N_ELEMENTS) EQ 3) THEN BEGIN
        myimg_0 = readpds(file[0], /silent, /noscale)
        myimg_1 = readpds(file[1], /silent, /noscale)
        myimg_2 = readpds(file[2], /silent, /noscale)
        s=size(myimg_0.image,/dimension)
        RGB=intarr(3,s[0],s[1])
        New_RGB=fltarr(3,s[0],s[1]) ;Used in 'save_image' event below.
        scaled_RGB=intarr(3,x_val,y_val) ;Used in this IF statement.
        RGB[0,*,*]= myimg_0.image
        RGB[1,*,*]= myimg_1.image
        RGB[2,*,*]= myimg_2.image
        scaled_RGB[0,*,*] = congrid(myimg_0.image, x_val, y_val, /center)
        scaled_RGB[1,*,*] = congrid(myimg_1.image, x_val, y_val, /center)
        scaled_RGB[2,*,*] = congrid(myimg_2.image, x_val, y_val, /center)
        TVSCL, scaled_RGB, true=1
    
        progressBar->Update, (1)*50
    
        ;save procedure starts here:
    
        length = strlen(file[0])
        filter_no_1 = strmid(file[0], (length - 8), 2)
        filter_no_2 = strmid(file[1], (length - 8), 2)
        filter_no_3 = strmid(file[2], (length - 8), 2)
        myoutfile = 'RGB-  -  -  .png'
        strput, myoutfile, filter_no_1, 4
        strput, myoutfile, filter_no_2, 7
        strput, myoutfile, filter_no_3, 10
        dir_length = strpos(file[0], '\', /reverse_search)
        myoutdir = strmid(file[0], 0, dir_length + 1)
        myoutfile = myoutdir + myoutfile
    
        ;Scale the RGB image data from 16-bit to 8-bit. This can be read by the XROI widget.
    
        New_RGB[2,*,*] = (!D.table_size - 1)* (FLOAT(RGB[2,*,*] - min(RGB[2,*,*]))/FLOAT(max(RGB[2,*,*]) - min(RGB[2,*,*])))
        New_RGB[1,*,*] = (!D.table_size - 1)* (FLOAT(RGB[1,*,*] - min(RGB[1,*,*]))/FLOAT(max(RGB[1,*,*]) - min(RGB[1,*,*])))
        New_RGB[0,*,*] = (!D.table_size - 1)* (FLOAT(RGB[0,*,*] - min(RGB[0,*,*]))/FLOAT(max(RGB[0,*,*]) - min(RGB[0,*,*])))
    
    ; png image file is written of the data created above
    
        write_png, myoutfile, New_RGB
    
        ENDIF
        
    ; If only one PDS image is selected:
    
        IF (SIZE(file, /N_ELEMENTS) EQ 1) THEN BEGIN
        myimg_0 = readpds(file[0], /silent, /noscale)
        TVSCL, congrid(myimg_0.image, x_val, y_val, /center)
        progressBar->Update, (1)*50
    
        ; Take myinfile string and change 'img' extension to 'png' extension.
        ; First find the length of the string and 'myinfile' size
    
        length = strlen(file[0])
        s1=size(file,/dimension)
    
        ;Create a new string array for the output file path and assign 'myinfile'.
    
        myoutfile = strarr(1)
        myoutfile[*] = file[0]
    
        ;Change 'img' to 'png', and output new PNG image.
    
        strput, myoutfile, 'png', (length - 3)
    
        ;Scale the image data from 16-bit to 8-bit. This can be read by the XROI widget.
    
        scaled_image = (!D.table_size - 1)* (FLOAT(myimg_0.image - min(myimg_0.image))/FLOAT(max(myimg_0.image) - min(myimg_0.image)))
    
    ; PNG image file is written:
    
        write_png, myoutfile, scaled_image
    
        ENDIF
        
        progressBar->Destroy
        Obj_Destroy, progressBar
      ENDIF
        IF (SIZE(file, /N_ELEMENTS) NE 3 AND SIZE(file, /N_ELEMENTS) NE 1) THEN BEGIN
        Message = DIALOG_MESSAGE("SELECT 1 PDS RAD FILE, OR 3 PDS RAD FILES",/INFORMATION)
        ENDIF
    ENDIF ELSE BEGIN
    Message = DIALOG_MESSAGE("NO PDS RAD DATA SELECTED",/INFORMATION)
    ENDELSE
  END
  
  'Generate_RStar' : BEGIN

  ; This creates the sub-widget for Generate RStar for AUPE data, but calculates RStar for PDS data without the
  ; need of a sub-widget. AUPE data also bypasses the sub-widget code and continues the same as the PDS data,
  ; once the function is called from the sub-widget.
 
IF (file[0] NE '') THEN BEGIN
IF Rstar_check EQ 1 OR Rstar_check EQ 0 THEN BEGIN

; AUPE sub-widgets start here
; Four different versions of sub-widget can be created here, depending on variables calculated previously

IF aupe_check EQ 1 THEN BEGIN

; Version #1 : buttons will appear that allow the user to get the exposure values, find Radiance Scaling 
; Factor and Offset values from a different image file and generate R* for LWAC and for RWAC

IF count_exp EQ 0 AND (count_slp_1 EQ 0 AND count_slp_2 EQ 0) THEN BEGIN
  IF mistake4 EQ 0 THEN BEGIN
  WIDGET_CONTROL, fifth_base, /REALIZE
  WIDGET_CONTROL, drawexp_1, GET_VALUE=drawexp_1id
  WIDGET_CONTROL, fifth_base, SET_UVALUE=drawexp_1id
  WSET, drawexp_1id
  CD, C=c
  IF c NE img_dir THEN BEGIN
  CD, img_dir
  ENDIF
  restore, 'title_exp.sav'
  TVSCL, image5, true=1
  mistake4 = 1
  aupe_check = 2
  ENDIF ELSE BEGIN
  message = DIALOG_MESSAGE("Currently this button cannot be pressed twice due to a bug in the program :( please restart if you need to use this button", /INFORMATION)
  ENDELSE
ENDIF

; Version #2 : buttons will appear that allow the user to find Radiance Scaling 
; Factor and Offset values from a different image file and generate R* for LWAC and for RWAC
; Here, getting the exposure values is left out as the file already exists

IF count_exp NE 0 AND (count_slp_1 EQ 0 AND count_slp_2 EQ 0) THEN BEGIN
  IF mistake5 EQ 0 THEN BEGIN
  WIDGET_CONTROL, sixth_base, /REALIZE
  WIDGET_CONTROL, drawexp_2, GET_VALUE=drawexp_2id
  WIDGET_CONTROL, sixth_base, SET_UVALUE=drawexp_2id
  WSET, drawexp_2id
  CD, C=c
  IF c NE img_dir THEN BEGIN
  CD, img_dir
  ENDIF
  restore, 'title_exp.sav'
  TVSCL, image5, true=1
  mistake5 = 1
  aupe_check = 2
  ENDIF ELSE BEGIN
  message = DIALOG_MESSAGE("Currently this button cannot be pressed twice due to a bug in the program :( please restart if you need to use this button", /INFORMATION)
  ENDELSE
ENDIF

; Version #3 : buttons will appear that allow the user to get the exposure values and generate R* for LWAC and
; for RWAC
; Here, finding the radiance scaling factor and offset is left out as these files already exist within the
; directory

IF count_exp EQ 0 AND (count_slp_1 EQ 1 OR count_slp_2 EQ 1) THEN BEGIN
  IF mistake6 EQ 0 THEN BEGIN
 ; count_exp = 1
 ; CD, directory
  WIDGET_CONTROL, seventh_base, /REALIZE
  WIDGET_CONTROL, drawexp_3, GET_VALUE=drawexp_3id
  WIDGET_CONTROL, seventh_base, SET_UVALUE=drawexp_3id
  WSET, drawexp_3id
  CD, C=c
  IF c NE img_dir THEN BEGIN
  CD, img_dir
  ENDIF
  restore, 'title_exp.sav'
  TVSCL, image5, true=1
  mistake6 = 1
  aupe_check = 2
  ENDIF ELSE BEGIN
  message = DIALOG_MESSAGE("Currently this button cannot be pressed twice due to a bug in the program :( please restart if you need to use this button", /INFORMATION)
  ENDELSE
ENDIF

; Version #4 : buttons will appear that allow the user to generate R* for LWAC and for RWAC
; Here, both 'getting the exposure values' and 'finding the radiometric sclaing factor and offset' are left out

IF count_exp EQ 1 AND (count_slp_1 EQ 1 OR count_slp_2 EQ 1) THEN BEGIN
  IF mistake7 EQ 0 THEN BEGIN
 ; count_exp = 1
 ; CD, directory
  WIDGET_CONTROL, eighth_base, /REALIZE
  WIDGET_CONTROL, drawexp_4, GET_VALUE=drawexp_4id
  WIDGET_CONTROL, eighth_base, SET_UVALUE=drawexp_4id
  WSET, drawexp_4id
  CD, C=c
  IF c NE img_dir THEN BEGIN
  CD, img_dir
  ENDIF
  restore, 'title_exp.sav'
  TVSCL, image5, true=1
  mistake7 = 1
  aupe_check = 2
  ENDIF ELSE BEGIN
  message = DIALOG_MESSAGE("Currently this button cannot be pressed twice due to a bug in the program :( please restart if you need to use this button", /INFORMATION)
  ENDELSE
ENDIF
ENDIF ELSE BEGIN

; Both AUPE and PDS data follow allong the code from this point onwards

IF count_exp EQ 1 AND (count_slp_1 EQ 1 OR count_slp_2 EQ 1) THEN BEGIN
fileinto = myoutdir + 'radiometric_scaling_factor_wavelength_740.dat'
filesearch = file_search(fileinto, count = generatecount)
file_R = file_E
IF generatecount EQ 1 THEN BEGIN
file_R = ''
ENDIF

; The user needs to select the image files they wish to turn into RStar data

IF file_R[0] EQ '' THEN BEGIN
IF Rstar_check EQ 1 THEN BEGIN
filters = ['*.img']
path_in = !DIR+'/examples/data'
file_R = DIALOG_PICKFILE(PATH=path_in, /MULTIPLE_FILES, /READ, $
FILTER = filters, /FIX_FILTER)
dir_length = strpos(file_R[0], '\', /reverse_search)
myoutdir = strmid(file_R[0], 0, dir_length + 1)
ENDIF
IF Rstar_check EQ 0 THEN BEGIN
filters = ['*.png']
path_in = !DIR+'/examples/data'
file_R = DIALOG_PICKFILE(PATH=path_in, /MULTIPLE_FILES, /READ, $
FILTER = filters, /FIX_FILTER)
dir_length = strpos(file_R[0], '\', /reverse_search)
myoutdir = strmid(file_R[0], 0, dir_length + 1)
ENDIF
ENDIF


IF (file_R[0] NE '') THEN BEGIN

; The exposure values of the images are taken out of their file at this point ( for AUPE data only)

IF Rstar_check EQ 0 THEN BEGIN
filename_all = 'all_exposure.dat'
CD, myoutdir
A = findgen(6)
OPENR, 2, filename_all
READF,2,A
CLOSE,2 
print, 'A = ', A
ENDIF

; The create_file_wavelengths variable creates a string which will later be placed into a command prompt window. A file containing all of the wavelengths
; will be created

number_of_files=size(file_R,/dimension)
create_file_wavelengths =  '(echo '

; Beginning of progress bar

progressBar = Obj_New("SHOWPROGRESS")
progressBar->Start

 
FOR i=0, (number_of_files[0] - 1) DO BEGIN

; Radiance scaling factor and offset are found for PDS data

IF Rstar_check EQ 1 THEN BEGIN
myimg_0 = readpds(file_R[i], /silent, /noscale)
label = headpds(file_R[i],/silent)
RADIANCE_SCALING_FACTOR = pdspar(label, 'RADIANCE_SCALING_FACTOR')
RADIANCE_OFFSET = pdspar(label, 'RADIANCE_OFFSET')
s0=size(myimg_0.image,/dimension);
RStar = fltarr(s0[0],s0[1], /NOZERO)
RStar[*,*] = myimg_0.image

FILTER_NAME = pdspar(label, 'FILTER_NAME')
Filtername = FILTER_NAME[1]
Filter=long(strmid(Filtername,10,3))
filter_new = strcompress(STRING(filter), /REMOVE_ALL)   
create_file_wavelengths = create_file_wavelengths + filter_new + ' && echo '
ENDIF

; I am here!
IF Rstar_check EQ 0 THEN BEGIN
myimg_0 = read_png(file_R[i])
length = strlen(myoutdir)
IF (strlen(file_R[i]) EQ (length + 6)) OR (strlen(file_R[i]) EQ (length + 7)) THEN BEGIN
IF (strlen(file_R[i]) EQ (length + 6)) THEN BEGIN
name_of_filter = strmid(file_R[i], length, 6)
ENDIF
IF (strlen(file_R[i]) EQ (length + 7)) THEN BEGIN
name_of_filter = strmid(file_R[i], length, 7)
ENDIF
ENDIF ELSE BEGIN
message = DIALOG_MESSAGE("Please make sure that your images follow the naming convention of 'f1.png', 'f2.png', etc and that no image name is greater than f99", /INFORMATION)
ENDELSE

print, 'name of filter = ', name_of_filter
IF name_of_filter EQ 'f4.png' OR name_of_filter EQ 'f04.png' THEN BEGIN
CD, (myoutdir)
Offset_slope = FLTARR(2)
OPENR, 6, 'radiometric_scaling_factor_wavelength_438.dat'
READF,6,offset_slope
CLOSE,6
RADIANCE_SCALING_FACTOR = offset_slope[1]
RADIANCE_OFFSET = offset_slope[0]
;;print, 'RADIANCE_SCALING_FACTOR = ', RADIANCE_SCALING_FACTOR
;;print, 'RADIANCE_OFFSET = ', RADIANCE_OFFSET
filter_new = '438'
create_file_wavelengths = create_file_wavelengths + filter_new + ' && echo '
print, 'filter = 4'
ENDIF
IF name_of_filter EQ 'f5.png' OR name_of_filter EQ 'f05.png' THEN BEGIN
CD, (myoutdir)
Offset_slope = FLTARR(2)
OPENR, 6, 'radiometric_scaling_factor_wavelength_500.dat'
READF,6,offset_slope
CLOSE,6
RADIANCE_SCALING_FACTOR = offset_slope[1]
RADIANCE_OFFSET = offset_slope[0]
;;print, 'RADIANCE_SCALING_FACTOR = ', RADIANCE_SCALING_FACTOR
;;print, 'RADIANCE_OFFSET = ', RADIANCE_OFFSET
filter_new = '500'
create_file_wavelengths = create_file_wavelengths + filter_new + ' && echo '
print, 'filter = 5'
ENDIF
IF name_of_filter EQ 'f6.png' OR name_of_filter EQ 'f06.png' THEN BEGIN
CD, (myoutdir)
Offset_slope = FLTARR(2)
OPENR, 6, 'radiometric_scaling_factor_wavelength_532.dat'
READF,6,offset_slope
CLOSE,6
RADIANCE_SCALING_FACTOR = offset_slope[1]
RADIANCE_OFFSET = offset_slope[0]
;;print, 'RADIANCE_SCALING_FACTOR = ', RADIANCE_SCALING_FACTOR
;;print, 'RADIANCE_OFFSET = ', RADIANCE_OFFSET
filter_new = '532'
create_file_wavelengths = create_file_wavelengths + filter_new + ' && echo '
print, 'filter = 6'
ENDIF
IF name_of_filter EQ 'f7.png' OR name_of_filter EQ 'f07.png' THEN BEGIN
CD, (myoutdir)
Offset_slope = FLTARR(2)
OPENR, 6, 'radiometric_scaling_factor_wavelength_568.dat'
READF,6,offset_slope
CLOSE,6
RADIANCE_SCALING_FACTOR = offset_slope[1]
RADIANCE_OFFSET = offset_slope[0]
;;print, 'RADIANCE_SCALING_FACTOR = ', RADIANCE_SCALING_FACTOR
;;print, 'RADIANCE_OFFSET = ', RADIANCE_OFFSET
filter_new = '568'
create_file_wavelengths = create_file_wavelengths + filter_new + ' && echo '
print, 'filter = 7'
ENDIF
IF name_of_filter EQ 'f8.png' OR name_of_filter EQ 'f08.png' THEN BEGIN
CD, (myoutdir)
Offset_slope = FLTARR(2)
OPENR, 6, 'radiometric_scaling_factor_wavelength_610.dat'
READF,6,offset_slope
CLOSE,6
RADIANCE_SCALING_FACTOR = offset_slope[1]
RADIANCE_OFFSET = offset_slope[0]
;print, 'RADIANCE_SCALING_FACTOR = ', RADIANCE_SCALING_FACTOR
;print, 'RADIANCE_OFFSET = ', RADIANCE_OFFSET
filter_new = '610'
create_file_wavelengths = create_file_wavelengths + filter_new + ' && echo '
print, 'filter = 8'
ENDIF
IF name_of_filter EQ 'f9.png' OR name_of_filter EQ 'f09.png' THEN BEGIN
CD, (myoutdir)
Offset_slope = FLTARR(2)
OPENR, 6, 'radiometric_scaling_factor_wavelength_671.dat'
READF,6,offset_slope
CLOSE,6
RADIANCE_SCALING_FACTOR = offset_slope[1]
RADIANCE_OFFSET = offset_slope[0]
;print, 'RADIANCE_SCALING_FACTOR = ', RADIANCE_SCALING_FACTOR
;print, 'RADIANCE_OFFSET = ', RADIANCE_OFFSET
filter_new = '671'
create_file_wavelengths = create_file_wavelengths + filter_new + ' && echo '
print, 'filter = 9'
ENDIF
s0=size(myimg_0,/dimension);
RStar = fltarr(s0[0],s0[1], /NOZERO)
RStar[*,*] = myimg_0
ENDIF
;print, 'rstar before multiplication = ', rstar[0]
;print, 'RADIANCE_SCALING_FACTOR = ', RADIANCE_SCALING_FACTOR
;print, 'RADIANCE_OFFSET = ', RADIANCE_OFFSET
;;print, 'RADIANCE_SCALING_FACTOR = = = = = = ', RADIANCE_SCALING_FACTOR[0]
;;print, 'RStar[0:10] = ', RStar[0:10]
;print, 'Rstar before A division = ', Rstar[0]
IF rstar_check EQ 0 THEN BEGIN
Rstar = Rstar/A[i]
RStar = (RStar / RADIANCE_SCALING_FACTOR[0])
ENDIF
IF rstar_check EQ 1 THEN BEGIN
RStar = (RStar * RADIANCE_SCALING_FACTOR[0]) + RADIANCE_OFFSET[0]
ENDIF
;print, 'rstar after multiplication = ', rstar[0]
;;print, 'RStar[0:10] = ', RStar[0:10]
; Take myinfile string and change '.img' extension to 'RSt' extension.
; First find the length of the string and 'myinfile' size.
length = strlen(file_R[i])
s1=size(file_R,/dimension)
;Create a new string array for the output file path and assign 'myinfile'.
myoutfilenew = strarr(1)
myoutfilenew[*] = file_R[i]
;Change '.img' to '.Rst', and output new R* file.
strput, myoutfilenew, 'RSt', (length - 3)
write_csv, myoutfilenew, RStar
;print, 'myoutfilenew =', myoutfilenew
;pixelnew = read_csv(myoutfilenew)

progressBar->Update, (i+1)*10
ENDFOR

IF rstar_check EQ 1 THEN BEGIN
myimg_0 = readpds(file_R[0], /silent, /noscale) 
s0=size(myimg_0.image,/dimension)
;print, 'S0 = ', s0
ENDIF
IF rstar_check EQ 0 THEN BEGIN
myimg_0 = read_png(file_R[0]) 
s0=size(myimg_0,/dimension)
ENDIF
CD, (myoutdir)
width = strcompress(STRING(s0[0]), /REMOVE_ALL)
;print, 'width = ', width
height = strcompress(STRING(s0[1]), /REMOVE_ALL)
;print, 'height = ', height 
create_file_dimensions =  '(echo ' + width + ' && echo ' + height + ') > file_dimensions.dat'
;print, 'create_file_dimensions = ', create_file_dimensions
SPAWN, create_file_dimensions

length_of_wave = strlen(create_file_wavelengths)
;print, 'length_of_wave = ', length_of_wave
final_length = length_of_wave - 9
create_file_wavelengths = strmid(create_file_wavelengths, 0, final_length)
;print, 'create_file_wavelengths = ', create_file_wavelengths
create_file_wavelengths =  create_file_wavelengths + ') > all_wavelengths.dat'
;print, 'create_file_wavelengths = ', create_file_wavelengths
SPAWN, create_file_wavelengths

progressBar->Destroy
Obj_Destroy, progressBar
ENDIF ELSE BEGIN
Message = DIALOG_MESSAGE("NO R* FILES SELECTED",/INFORMATION)
ENDELSE
;ENDIF ELSE BEGIN
;Message = DIALOG_MESSAGE("Please press the 'Generate R* for RWAC' button to process RWAC data",/INFORMATION)
;ENDELSE
ENDIF
ENDELSE ;;;;;;!!!
ENDIF ELSE BEGIN
Message = DIALOG_MESSAGE("Please select either PDS or AUPE data",/INFORMATION)
ENDELSE
ENDIF ELSE BEGIN
Message = DIALOG_MESSAGE("Please select either PDS or AUPE data",/INFORMATION)
ENDELSE
  END
  
  'Generate_RStar_RWAC' : BEGIN
  IF count_exp EQ 1 AND count_slp_1 EQ 1 OR count_slp_2 EQ 1 THEN BEGIN
fileinto = myoutdir + 'radiometric_scaling_factor_wavelength_438.dat'
filesearch = file_search(fileinto, count = generatecount)
file_R = file_E
IF generatecount EQ 1 THEN BEGIN
file_R = ''
ENDIF
IF file_R[0] EQ '' THEN BEGIN
IF Rstar_check EQ 0 THEN BEGIN
filters = ['*.png']
path_in = !DIR+'/examples/data'
file_R = DIALOG_PICKFILE(PATH=path_in, /MULTIPLE_FILES, /READ, $
FILTER = filters, /FIX_FILTER)
dir_length = strpos(file_R[0], '\', /reverse_search)
myoutdir = strmid(file_R[0], 0, dir_length + 1)
ENDIF
ENDIF
IF (file_R[0] NE '') THEN BEGIN

IF Rstar_check EQ 0 THEN BEGIN
filename_all = 'all_exposure.dat'
CD, myoutdir
A = findgen(6)
OPENR, 2, filename_all
READF,2,A
CLOSE,2 
print, 'A = ', A
ENDIF

number_of_files=size(file_R,/dimension)
create_file_wavelengths =  '(echo '
;;;Beginning of progress bar code A;;;
progressBar = Obj_New("SHOWPROGRESS")
progressBar->Start
;;;End of progress bar code A;;;
 
FOR i=0, (number_of_files[0] - 1) DO BEGIN

IF Rstar_check EQ 0 THEN BEGIN
myimg_0 = read_png(file_R[i])
print, 'myimg = ', myimg_0[0]
;help,transparent
;help, myimg_0
length = strlen(myoutdir)
;;print, 'myoutdir = ', myoutdir
;;print, 'length = ', length
IF (strlen(file_R[i]) EQ (length + 6)) OR (strlen(file_R[i]) EQ (length + 7)) THEN BEGIN
IF (strlen(file_R[i]) EQ (length + 6)) THEN BEGIN
name_of_filter = strmid(file_R[i], length, 6)
;;print, 'name of filter = ', name_of_filter
ENDIF
IF (strlen(file_R[i]) EQ (length + 7)) THEN BEGIN
name_of_filter = strmid(file_R[i], length, 7)
;;print, '+7'
ENDIF
ENDIF ELSE BEGIN
message = DIALOG_MESSAGE("Please make sure that your images follow the naming convention of 'f1.png', 'f2.png', etc and that no image name is greater than f99", /INFORMATION)
ENDELSE
print, 'name of filter = ', name_of_filter
IF name_of_filter EQ 'f4.png' OR name_of_filter EQ 'f04.png' THEN BEGIN
CD, (myoutdir)
Offset_slope = FLTARR(2)
OPENR, 6, 'radiometric_scaling_factor_wavelength_740.dat'
READF,6,offset_slope
CLOSE,6
RADIANCE_SCALING_FACTOR = offset_slope[1]
RADIANCE_OFFSET = offset_slope[0]
;;print, 'RADIANCE_SCALING_FACTOR = ', RADIANCE_SCALING_FACTOR
;;print, 'RADIANCE_OFFSET = ', RADIANCE_OFFSET
filter_new = '740'
create_file_wavelengths = create_file_wavelengths + filter_new + ' && echo '
print, 'filter = 4'
ENDIF
IF name_of_filter EQ 'f5.png' OR name_of_filter EQ 'f05.png' THEN BEGIN
CD, (myoutdir)
Offset_slope = FLTARR(2)
OPENR, 6, 'radiometric_scaling_factor_wavelength_780.dat'
READF,6,offset_slope
CLOSE,6
RADIANCE_SCALING_FACTOR = offset_slope[1]
RADIANCE_OFFSET = offset_slope[0]
;;print, 'RADIANCE_SCALING_FACTOR = ', RADIANCE_SCALING_FACTOR
;;print, 'RADIANCE_OFFSET = ', RADIANCE_OFFSET
filter_new = '780'
create_file_wavelengths = create_file_wavelengths + filter_new + ' && echo '
print, 'filter = 5'
ENDIF
IF name_of_filter EQ 'f6.png' OR name_of_filter EQ 'f06.png' THEN BEGIN
CD, (myoutdir)
Offset_slope = FLTARR(2)
OPENR, 6, 'radiometric_scaling_factor_wavelength_832.dat'
READF,6,offset_slope
CLOSE,6
RADIANCE_SCALING_FACTOR = offset_slope[1]
RADIANCE_OFFSET = offset_slope[0]
;;print, 'RADIANCE_SCALING_FACTOR = ', RADIANCE_SCALING_FACTOR
;;print, 'RADIANCE_OFFSET = ', RADIANCE_OFFSET
filter_new = '832'
create_file_wavelengths = create_file_wavelengths + filter_new + ' && echo '
print, 'filter = 6'
ENDIF
IF name_of_filter EQ 'f7.png' OR name_of_filter EQ 'f07.png' THEN BEGIN
CD, (myoutdir)
Offset_slope = FLTARR(2)
OPENR, 6, 'radiometric_scaling_factor_wavelength_900.dat'
READF,6,offset_slope
CLOSE,6
RADIANCE_SCALING_FACTOR = offset_slope[1]
RADIANCE_OFFSET = offset_slope[0]
;;print, 'RADIANCE_SCALING_FACTOR = ', RADIANCE_SCALING_FACTOR
;;print, 'RADIANCE_OFFSET = ', RADIANCE_OFFSET
filter_new = '900'
create_file_wavelengths = create_file_wavelengths + filter_new + ' && echo '
print, 'filter = 7'
ENDIF
IF name_of_filter EQ 'f8.png' OR name_of_filter EQ 'f08.png' THEN BEGIN
CD, (myoutdir)
Offset_slope = FLTARR(2)
OPENR, 6, 'radiometric_scaling_factor_wavelength_950.dat'
READF,6,offset_slope
CLOSE,6
RADIANCE_SCALING_FACTOR = offset_slope[1]
RADIANCE_OFFSET = offset_slope[0]
;print, 'RADIANCE_SCALING_FACTOR = ', RADIANCE_SCALING_FACTOR
;print, 'RADIANCE_OFFSET = ', RADIANCE_OFFSET
filter_new = '950'
create_file_wavelengths = create_file_wavelengths + filter_new + ' && echo '
print, 'filter = 8'
ENDIF
IF name_of_filter EQ 'f9.png' OR name_of_filter EQ 'f09.png' THEN BEGIN
CD, (myoutdir)
Offset_slope = FLTARR(2)
OPENR, 6, 'radiometric_scaling_factor_wavelength_1000.dat'
READF,6,offset_slope
CLOSE,6
RADIANCE_SCALING_FACTOR = offset_slope[1]
RADIANCE_OFFSET = offset_slope[0]
;print, 'RADIANCE_SCALING_FACTOR = ', RADIANCE_SCALING_FACTOR
;print, 'RADIANCE_OFFSET = ', RADIANCE_OFFSET
filter_new = '1000'
create_file_wavelengths = create_file_wavelengths + filter_new + ' && echo '
print, 'filter = 9'
ENDIF
s0=size(myimg_0,/dimension);
RStar = fltarr(s0[0],s0[1], /NOZERO)
RStar[*,*] = myimg_0
ENDIF
IF rstar_check EQ 0 THEN BEGIN
FOREACH element, rstar, index DO BEGIN
IF element EQ '255' THEn BEGIN
print, '255'
ENDIF
IF element GT '255' THEN BEGIN
print, 'whhhaaatt??'
ENDIF
ENDFOREACH
Rstar = Rstar/A[i]
print, 'A[i] = ', A[i]
RStar = (RStar / RADIANCE_SCALING_FACTOR[0])
print, 'RADIANCE_SCALING_FACTOR[0] = ', RADIANCE_SCALING_FACTOR[0]
print, '(255/A[i])/RADIANCE_SCALING_FACTOR[0] = ', (255/A[i])/RADIANCE_SCALING_FACTOR[0]
ENDIF
; Take myinfile string and change '.img' extension to 'RSt' extension.
; First find the length of the string and 'myinfile' size.
length = strlen(file_R[i])
s1=size(file_R,/dimension)
;Create a new string array for the output file path and assign 'myinfile'.
myoutfilenew = strarr(1)
myoutfilenew[*] = file_R[i]
;Change '.img' to '.Rst', and output new R* file.
strput, myoutfilenew, 'RSt', (length - 3)
write_csv, myoutfilenew, RStar
progressBar->Update, (i+1)*10
ENDFOR

IF rstar_check EQ 0 THEN BEGIN
myimg_0 = read_png(file_R[0]) 
s0=size(myimg_0,/dimension)
ENDIF
CD, (myoutdir)
width = strcompress(STRING(s0[0]), /REMOVE_ALL)
;print, 'width = ', width
height = strcompress(STRING(s0[1]), /REMOVE_ALL)
;print, 'height = ', height 
create_file_dimensions =  '(echo ' + width + ' && echo ' + height + ') > file_dimensions.dat'
;print, 'create_file_dimensions = ', create_file_dimensions
SPAWN, create_file_dimensions

length_of_wave = strlen(create_file_wavelengths)
;print, 'length_of_wave = ', length_of_wave
final_length = length_of_wave - 9
create_file_wavelengths = strmid(create_file_wavelengths, 0, final_length)
;print, 'create_file_wavelengths = ', create_file_wavelengths
create_file_wavelengths =  create_file_wavelengths + ') > all_wavelengths.dat'
;print, 'create_file_wavelengths = ', create_file_wavelengths
SPAWN, create_file_wavelengths

progressBar->Destroy
Obj_Destroy, progressBar
ENDIF ELSE BEGIN
Message = DIALOG_MESSAGE("NO R* FILES SELECTED",/INFORMATION)
ENDELSE
ENDIF
  END
  
    'Get_exposure_values' : BEGIN
file_E= DIALOG_PICKFILE(PATH=myoutdir, /MULTIPLE_FILES, /READ, $
FILTER='*.png', /FIX_FILTER)
IF file_E[0] NE '' THEN BEGIN
dir_length = strpos(file_E[0], '\', /reverse_search)
myoutdir = strmid(file_E[0], 0, dir_length + 1)
number_of_files=size(file_E,/dimension)
progressBar = Obj_New("SHOWPROGRESS")
progressBar->Start 
spawn_exp = 'identify -format "%[AU_exposureTime]\n" '
FOR i=0, (number_of_files[0] - 1) DO BEGIN
print, 'strlen(File_E[i]) = ', strlen(File_E[i])
print, 'strlen(myoutdir) = ', strlen(myoutdir)
IF (strlen(File_E[i]) - strlen(myoutdir)) EQ 7 THEN BEGIN
filter_exp = strmid(file_E[i], strlen(myoutdir), 7)
filter_exp = strcompress(STRING(filter_exp), /REMOVE_ALL)
print, 'filter_exp = ', filter_exp
ENDIF
IF (strlen(File_E[i]) - strlen(myoutdir)) EQ 6 THEN BEGIN
filter_exp = strmid(file_E[i], strlen(myoutdir), 6)
filter_exp = strcompress(STRING(filter_exp), /REMOVE_ALL)
print, 'filter_exp = ', filter_exp
ENDIF ELSE BEGIN
;;put in message about naming convention
ENDELSE
spawn_exp = spawn_exp + filter_exp + ' '
progressBar->Update, (1)*20
ENDFOR
spawn_exp = spawn_exp + '> all_exposure.dat'
CD, (myoutdir) 
SPAWN, spawn_exp
progressBar->Destroy
Obj_Destroy, progressBar
  count_exp = 1
ENDIF ELSE BEGIN
;;put message about choosing filesor no files were selected
ENDELSE
END

'Get_Radiance_Scaling_Factor_Values' : BEGIN
path_in = myoutdir
file4 = DIALOG_PICKFILE(PATH=path_in, /MULTIPLE_FILES, /READ, $
FILTER='*.dat', /FIX_FILTER)
dir_position = strpos(file4[0], '\', /reverse_search)
myoutdir_copy = strmid(file4[0], 0, dir_position + 1)
print, file4
FILE_COPY, file4, myoutdir
  count_slp_1 = 1
END
  
  'Create_ROI_graph' : BEGIN
  IF mistake2 EQ 0 THEN BEGIN
  IF rstar_check EQ 0 or rstar_check EQ 1 THEN BEGIN
  IF rstar_check EQ 0 THEN BEGIN
  ;CD, directory
  WIDGET_CONTROL, third_base, /REALIZE
  WIDGET_CONTROL, drawloadpds, GET_VALUE=drawloadpdsid
  WIDGET_CONTROL, drawloadpds_2, GET_VALUE=drawloadpdsid_2
  WIDGET_CONTROL, third_base, SET_UVALUE=drawloadpdsid
  WIDGET_CONTROL, third_base, SET_UVALUE=drawloadpdsid_2
  WSET, drawloadpdsid
  CD, C=c
  IF c NE img_dir THEN BEGIN
  CD, img_dir
  ENDIF
  restore, 'titleloadpds.sav'
  TVSCL, image_pds, true=1
  WSET, drawloadpdsid_2
  restore, 'lwac_and_rwac.sav'
  TVSCL, image7, true=1
  mistake2 = 1
  ENDIF
  IF rstar_check EQ 1 THEN BEGIN
  ;CD, directory
  WIDGET_CONTROL, ninth_base, /REALIZE
  WIDGET_CONTROL, drawroigraph, GET_VALUE=drawroigraphid
  WIDGET_CONTROL, ninth_base, SET_UVALUE=drawroigraphid
  WSET, drawroigraphid
  ;CD, C=c
  ;IF c NE img_dir THEN BEGIN
  CD, img_dir
 ; ENDIF
  restore, 'titleloadpds.sav'
  TVSCL, image_pds, true=1
  mistake2 = 1
  ENDIF
  ENDIF ELSE BEGIN
  message = DIALOG_MESSAGE("Please select AUPE or PDS data first", /INFORMATION)
  ENDELSE
  ENDIF ELSE BEGIN
  message = DIALOG_MESSAGE("Currently this button cannot be pressed twice due to a bug in the program :( please restart if you need to use this button", /INFORMATION)
  ENDELSE
  END
  
  'create_histogram' : BEGIN
  
      IF (file[0] NE '') THEN BEGIN
  ;    IF (mistake EQ 0) THEN BEGIN
      WIDGET_CONTROL, eleventh_base, /REALIZE;, BAD_ID= drawoffse
      WIDGET_CONTROL, draw_histoplot, GET_VALUE=draw_histoplotid;, BAD_ID= drawoffsetid
      ;IF (mistake EQ 0) THEN BEGIN
      WIDGET_CONTROL, eleventh_base, SET_UVALUE=draw_histoplotid;, BAD_ID= drawoffsetid
      ;ENDIF
      WSET, draw_histoplotid
      ;, BAD_ID= drawoffsetid

  
;  window,draw_histoplotid
  
   cgHistoplot, white_data, title = 'Histogram of ROIs on the Calibration Target', xtitle = 'Wavelength', /Fill, BINSIZE=1.0, MININPUT = 0, MAXINPUT = 250, POLYCOLOR=['white'], DATACOLORNAME = ['wheat']
   cgHistoplot, neutral_44_data, /Fill,  BINSIZE=1.0, /oplot, POLYCOLOR=['Light Gray'], DATACOLORNAME = ['Light Gray']
   cgHistoplot, neutral_70_data,/Fill, BINSIZE=1.0, /oplot, POLYCOLOR=['Medium gray'], DATACOLORNAME = ['Medium Gray']
   cgHistoplot, neutral_1_05_data, /Fill, BINSIZE=1.0, /oplot, POLYCOLOR=['Dark Gray'], DATACOLORNAME = ['Dark Gray']
   cgHistoplot, black_data, /Fill, BINSIZE=1.0,  /oplot, POLYCOLOR=['black'], DATACOLORNAME = ['black']
   cgHistoplot, blue_data,  /Fill, BINSIZE=1.0, /oplot, POLYCOLOR=['blue'], DATACOLORNAME = ['blue']
   cgHistoplot, green_data, /Fill, BINSIZE=1.0, /oplot, POLYCOLOR=['green'], DATACOLORNAME = ['green']
   cgHistoplot, red_data, /Fill, BINSIZE=1.0,  /oplot, POLYCOLOR=['red'], DATACOLORNAME = ['red']
   cgHistoplot, yellow_data, /Fill, BINSIZE=1.0,  /oplot, POLYCOLOR=['yellow'], DATACOLORNAME = ['yellow']
   
   
       ENDIF ELSE BEGIN
    Message = DIALOG_MESSAGE("PLEASE SELECT AUPE2 DATA",/INFORMATION)
    ENDELSE
   
  END
  
            
    'Generate_CIE_data_second' : BEGIN
    
    IF (file[0] NE '') THEN BEGIN
      IF (mistake_gen EQ 0) THEN BEGIN
      WIDGET_CONTROL, fourth_base, /REALIZE
      WIDGET_CONTROL, drawcie, GET_VALUE=drawcieid
      WIDGET_CONTROL, fourth_base, SET_UVALUE=drawcieid
      WSET, drawcieid
      CD, C=c
      IF c NE img_dir THEN BEGIN
      CD, img_dir
      ENDIF
      restore, 'cietitle.sav'
      TVSCL, image_gen_cie, true=1
      mistake_gen = 1
      ENDIF ELSE BEGIN
      message = DIALOG_MESSAGE("Currently this button cannot be pressed twice due to a bug in the program :( please restart if you need to use this button", /INFORMATION)
      ENDELSE
    ENDIF ELSE BEGIN
    Message = DIALOG_MESSAGE("PLEASE SELECT AUPE2 DATA",/INFORMATION)
    ENDELSE
  END
          
          
    'CIE_to_sRGB_second' : BEGIN
    
    IF (file[0] NE '') THEN BEGIN
      IF (mistake_srgb EQ 0) THEN BEGIN
      WIDGET_CONTROL, tenth_base, /REALIZE
      WIDGET_CONTROL, draw_generate, GET_VALUE=draw_generateid
      WIDGET_CONTROL, tenth_base, SET_UVALUE=draw_generateid
      WSET, draw_generateid
      CD, C=c
      IF c NE img_dir THEN BEGIN
      CD, img_dir
      ENDIF
      restore, 'cietosrgb.sav'
      TVSCL, image_srgb, true=1
      mistake_srgb = 1
      ENDIF ELSE BEGIN
      message = DIALOG_MESSAGE("Currently this button cannot be pressed twice due to a bug in the program :( please restart if you need to use this button", /INFORMATION)
      ENDELSE
    ENDIF ELSE BEGIN
    Message = DIALOG_MESSAGE("PLEASE SELECT AUPE2 DATA",/INFORMATION)
    ENDELSE
  END
  
  
  'Generate_CIE_data' : BEGIN
  
  IF (file(0) NE '') THEN BEGIN
IF RSTAR_CHECK EQ 1 THEN BEGIN
Message = DIALOG_MESSAGE("Please select Rstar files from highest wavelength to lowest wavelength",/INFORMATION)
ENDIF
path_in = !DIR+'/examples/data'
file4 = DIALOG_PICKFILE(PATH=path_in, /MULTIPLE_FILES, /READ, $
FILTER='*.Rst', /FIX_FILTER)
fileinto = myoutdir + 'file_dimensions.dat'
filesearch = file_search(fileinto, count = count_rstar)
count_rstar = STRCOMPRESS(count_rstar, /remove_all)
print, 'count = ', count_rstar
number_of_files=size(file4,/dimension)
IF count_rstar NE 0 THEN BEGIN 
IF (file4(0) NE '') THEN BEGIN
IF number_of_files EQ 6 THEN BEGIN
progressBar = Obj_New("SHOWPROGRESS")
progressBar->Start
rstar_spline_test = 1
      length_whole = strlen(file4[0])
      dir_length = strpos(file4[0], '\', /reverse_search)
      ;print, 'dir_length =', dir_length
      length_rstar = length_whole - dir_length
      myoutdir = strmid(file4[0], 0, dir_length + 1)
CD, myoutdir


;print, 'myoutdir = ', myoutdir
cd, myoutdir
progressBar->Update, (1)*5
file_size = FLTARR(2)
OPENR, 5, 'file_dimensions.dat'
READF,5,file_size
width = file_size(0)
height = file_size(1)
;print, 'width  = ', width 
;print, 'height = ', height
;print, 'file_size = ', file_size
CLOSE,5
progressBar->Update, (1)*5

file_wavelength = FLTARR(number_of_files)
OPENR, 4, 'all_wavelengths.dat'
READF,4,file_wavelength
;print, 'file_wavelength = ', file_wavelength
CLOSE,4
progressBar->Update, (1)*5
minimum = min(file_wavelength)
;print, 'minimum = ', minimum
maximum = max(file_wavelength)
;print, 'maximum = ', maximum
range = (maximum - minimum) + 1
;print, 'range = ', range

IF rstar_check EQ 1 THEN BEGIN
x_array = findgen(441) + 390 
spline_array = make_array(width, height, 441)
ENDIF
IF rstar_check EQ 0 THEN BEGIN
x_array = findgen(range) + minimum
spline_array = make_array(width, height, range)
ENDIF
;;print, 'x_array(0) = ', x_array(0)
IF rstar_check EQ 1 THEN BEGIN
;;print, 'file_wavelength(0)= ', file_wavelength(0)
x = REVERSE(file_wavelength)
ENDIF
IF rstar_check EQ 0 THEN BEGIN
x = file_wavelength
ENDIF
progressBar->Update, (1)*5
;print, 'x = ', x

IF number_of_files EQ 6 THEN BEGIN
file_name_string_0 = strmid(file4[0],dir_length + 1 , length_rstar)
file_name_string_1 = strmid(file4[1],dir_length + 1 , length_rstar)
file_name_string_2 = strmid(file4[2],dir_length + 1 , length_rstar)
file_name_string_3 = strmid(file4[3],dir_length + 1 , length_rstar)
file_name_string_4 = strmid(file4[4],dir_length + 1 , length_rstar)
file_name_string_5 = strmid(file4[5],dir_length + 1 , length_rstar)
file_0 = FLTARR(file_size[0], file_size[1])
file_1 = FLTARR(file_size[0], file_size[1])
file_2 = FLTARR(file_size[0], file_size[1])
file_3 = FLTARR(file_size[0], file_size[1])
file_4 = FLTARR(file_size[0], file_size[1])
file_5 = FLTARR(file_size[0], file_size[1])
;print, 'file_name_string_0 !!= ',file_name_string_0
;print, 'file_name_string_5 = ',file_name_string_5
OPENR, 9, file_name_string_0
READF,9,file_0
CLOSE,9
progressBar->Update, (1)*5
;print, 'file_0[0:10] = ', file_0[0:10]
OPENR, 15, file_name_string_1
READF,15,file_1
CLOSE,15
progressBar->Update, (1)*5
OPENR, 11, file_name_string_2
READF,11,file_2
CLOSE,11
OPENR, 12, file_name_string_3
READF,12,file_3
CLOSE,12
progressBar->Update, (1)*5
OPENR, 13, file_name_string_4
READF,13,file_4
CLOSE,13
progressBar->Update, (1)*5
OPENR, 14, file_name_string_5
READF,14,file_5
CLOSE,14
progressBar->Update, (1)*5
;print, 'file_5[0:10] = ', file_5[0:10]

foreach element, file_0, index do begin
  y = make_array(number_of_files)
  IF rstar_check EQ 1 THEN BEGIN
  y[5] = file_0[index]
  y[4] = file_1[index]
  y[3] = file_2[index]
  y[2] = file_3[index]
  y[1] = file_4[index]
  y[0] = file_5[index]
  ENDIF
  IF rstar_check EQ 0 THEN BEGIN
  y[0] = file_0[index]
  y[1] = file_1[index]
  y[2] = file_2[index]
  y[3] = file_3[index]
  y[4] = file_4[index]
  y[5] = file_5[index]
  ENDIF
  cubic_spline = SPLINE(x,y,x_array)
  progressBar->Update, (1)*5
flt = index/width
;;print, 'flt BEFORE = ', flt
h = RND(flt)
;;print, 'flt AFTER = ', flt
b = h*width
w = index - b

  spline_array[w,h,*] = cubic_spline

endforeach
progressBar->Update, (1)*5
;print, 'x_array(0) =====', x_array(0)
;window, 10
;plot, x_array, cubic_spline, xrange=[420,765]


;print, 'y = ', y
;print, 'flt = ', flt
;print, 'w = ', w
;print, 'h = ', h
;print, 'size = ', size(spline_array)
         ; CD, directory
          IF rstar_check EQ 1 THEN BEGIN
          progressBar->Update, (1)*5
            wavelength_array = indgen((((441)/5) + 1))/0.2 + 390
;  ;print, 'wavelength_array = ', wavelength_array
progressBar->Update, (1)*5
cd, img_dir
    x_bar = READ_SYLK("StdObsFuncs.slk", /ARRAY, /COLMAJOR, $
    STARTROW = (11), STARTCOL = 1, NCOLS = 1, NROWS = (89))
    y_bar = READ_SYLK("StdObsFuncs.slk", /ARRAY, /COLMAJOR, $
    STARTROW = (11), STARTCOL = 2, NCOLS = 1, NROWS = (89))
    z_bar = READ_SYLK("StdObsFuncs.slk", /ARRAY, /COLMAJOR, $
    STARTROW = (11), STARTCOL = 3, NCOLS = 1, NROWS = (89))
    progressBar->Update, (1)*10
  ;  ;print, 'z bar = ', z_bar
    t = indgen(441)+ 390
    m = 441
          ENDIF
          IF rstar_check EQ 0 THEN BEGIN 
          cd, img_dir
          progressBar->Update, (1)*5
  wavelength_array = indgen((((maximum - minimum)/5) + 1))/0.2 + minimum
  ;print, 'wavelength_array = ', wavelength_array

    x_bar = READ_SYLK("StdObsFuncs.slk", /ARRAY, /COLMAJOR, $
    STARTROW = (((minimum - 360)/5)+5), STARTCOL = 1, NCOLS = 1, NROWS = (((maximum - minimum)/5) + 1))
    y_bar = READ_SYLK("StdObsFuncs.slk", /ARRAY, /COLMAJOR, $
    STARTROW = (((minimum - 360)/5)+5), STARTCOL = 2, NCOLS = 1, NROWS = (((maximum - minimum)/5) + 1)) ; /USEDOUBLES) ;/USELONGS)
    ;;print, 'y_bar = ', y_bar
    z_bar = READ_SYLK("StdObsFuncs.slk", /ARRAY, /COLMAJOR, $
    STARTROW = (((minimum - 360)/5)+5), STARTCOL = 3, NCOLS = 1, NROWS = (((maximum - minimum)/5) + 1)) ; /USEDOUBLES) ;/USELONGS)
    ;print, 'z bar = ', z_bar
    t = indgen((maximum - minimum) + 1)+ minimum
    progressBar->Update, (1)*5
          ENDIF
 
 cubic_x_bar = spline(wavelength_array, x_bar, t)
 cubic_y_bar = spline(wavelength_array, y_bar, t)
 cubic_z_bar = spline(wavelength_array, z_bar, t)
progressBar->Update, (1)*5
 
; window, 11
;  plot, wavelength_array, x_bar, psym = 7, BACKGROUND = 'FFFFFF'xL, color = '000000'xL, $
 ;;; oplot, t, cubic_spline, color = 120, $
;   xrange=[(minimum - 20), (maximum + 20)], yrange=[0,2], /xstyle, /ystyle
;    oplot, wavelength_array, y_bar, psym = 7, color = '000000'xL
;    oplot, wavelength_array, z_bar, psym = 7, color = '000000'xL
;    oplot, t, cubic_x_bar, psym = -3, color = '0000FF'xL
;    oplot, t, cubic_y_bar, psym = -3, color = '007F00'xL
;    oplot, t, cubic_z_bar, psym = -3, color = 'FF0000'xL

 
 
   size_xbar = size((cubic_x_bar), /DIMENSIONS)
   size_ybar = size((cubic_y_bar), /DIMENSIONS)
   size_zbar = size((cubic_z_bar), /DIMENSIONS)

size_spline = size(spline_array)
w = size_spline(1)
h = size_spline(2)
d = size_spline(3)
progressBar->Update, (1)*5
;print, 'size_xbar = ', size_xbar 

;print, 'w = ', w
;print, 'h = ', h
;print, 'd = ', d
IF rstar_check EQ 0 THEN BEGIN
m = d
ENDIF
X = make_array(w,h)
Y = make_array(w,h)
Z = make_array(w,h)
spline_subset = spline_array(0:((w*h)-1))
  CD, myoutdir
;OpenW, lun, 'spline_subset.dat', /Get_LUN, WIDTH=250
;printF, lun, spline_subset
;Free_LUN, lun
progressBar->Update, (1)*5
foreach element, spline_subset, index do begin
  count = -1
  ;print, 'index = ', index
  ;;print, 'index = ', index
  little_array = index
  ;print, 'little_array = ', little_array
  ;;print, 'little_array = ', little_array
  bigger_array_x = make_array(size_xbar)
  bigger_array_y = make_array(size_ybar)
  bigger_array_z = make_array(size_zbar)
  WHILE (little_array + (w*h)) LT (index + (w*h*m)) OR (little_array + (w*h)) EQ (index + (w*h*m)) DO BEGIN
  count = count + 1
  ;;print, 'count = ',  count
  bigger_array_x[count] = (spline_array[little_array] * cubic_x_bar[count])
  bigger_array_y[count] = (spline_array[little_array] * cubic_y_bar[count])
  bigger_array_z[count] = (spline_array[little_array] * cubic_z_bar[count])
  little_array = little_array + (w*h)
  ENDWHILE
  total_x = TOTAL(bigger_array_x)
  total_y = TOTAL(bigger_array_y)
  total_z = TOTAL(bigger_array_z)
 ; IF rstar_check EQ 1 THEN BEGIN
 IF n EQ '' THEN BEGIN
 n = 0.03
 ENDIF
 
  X[index] = total_x*n;/10;(1/10);/1000;/0.001;10000;10
  Y[index] = total_y*n;/10;*(1/10);/0.1;/1000;/0.001;10000;10
  Z[index] = total_Z*n;/10;*(1/10);/0.1;/1000;/0.001;10000;10
  index_2 = index
;  ENDIF
;  IF rstar_check EQ 0 THEN BEGIN
;  X(index) = total_x*0.01;*0.000000001;/1000;/0.001;10000;10
;  Y(index) = total_y*0.01;*0.000000001;/1000;/0.001;10000;10
;  Z(index) = total_Z*0.01;*0.000000001;/1000;/0.001;10000;10
;  ENDIF
  ;print, 'done_some'
  ;print, 'x(index) = ', x(index)
  endforeach
  print, 'X = ', total_x*n
  progressBar->Update, (1)*5
;    CD, myoutdir
;OpenW, lun, 'Big X for dave.dat', /Get_LUN, WIDTH=250
;printF, lun, X
;Free_LUN, lun

;print, 'done'

;X_o = FLTARR(320,272)
;Y_o = FLTARR(320,272)
;Z_o = FLTARR(320,272)

;CD, 'G:\Daves CIE X etc\'
;OPENR, 9, 'CIE_X.dat'
;READF,9,X_o
;CLOSE,9
;OPENR, 12,'CIE_Y.dat'
;READF,12,Y_o
;CLOSE,12
;OPENR, 11, 'CIE_Z.dat'
;READF,11,Z_o
;CLOSE,11
          
little_x = (X/(X+Y+Z))
little_y = (Y/(X+Y+Z))
little_z = (Z/(X+Y+Z))
progressBar->Update, (1)*5

;little_x_rot = ROTATE(little_x, 2)
;little_y_rot = ROTATE(little_y, 2);

;little_x_rev = REVERSE(little_x_rot)
;little_y_rev = REVERSE(little_y_rot)


;  CD, myoutdir
;OpenW, lun, 'little_x_for_dave.dat', /Get_LUN, WIDTH=250
;printF, lun, little_x
;Free_LUN, lun
;  CD, myoutdir
;OpenW, lun, 'little_y_for_dave.dat', /Get_LUN, WIDTH=250
;printF, lun, little_y
;Free_LUN, lun


;print, 'size of little x = ',  size(little_x)

window,3
plot, little_x, little_y, psym = 7, $
  yrange=[0.0, 0.9], xrange=[0.0, 0.8], $
  BACKGROUND='FFFFFF'xL, COLOR='000000'xL

scaled_x = X * 255
scaled_y = Y * 255
scaled_z = Z * 255
scaled_little_y = (little_y * 255)
scaled_little_x = (little_x * 255)
scaled_little_y_d = ROUND(scaled_little_y)
size_sc = size(scaled_x, /DIMENSIONS)
;print, 'size_sc = ', size_sc
w = size_sc(0)
h = size_sc(1)

progressBar->Update, (1)*5

IF w EQ h THEN BEGIN
x_val = 450
y_val = 450
ENDIF
IF w GT h THEN BEGIN
x_val = 450
y_val = FIX((FLOAT(h)/FLOAT(w)) * 450)
ENDIF
IF w LT h THEN BEGIN
x_val = FIX((FLOAT(w)/FLOAT(h)) * 450)
y_val = 450
ENDIF
progressBar->Destroy
Obj_Destroy, progressBar
;window,2,xsize=x_val,ysize=y_val
;loadct,0 
;TV, congrid(scaled_little_y_d, x_val, y_val, /center)

ENDIF ELSE BEGIN
Message = DIALOG_MESSAGE("Please select 6 R* (.Rst) files",/INFORMATION)
ENDELSE
ENDIF ELSE BEGIN
Message = DIALOG_MESSAGE("Please select 6 R* (.Rst) files",/INFORMATION)
ENDELSE
;print, 'done'
ENDIF ELSE BEGIN
Message = DIALOG_MESSAGE("Please select R* (.Rst) files",/INFORMATION)
ENDELSE
ENDIF ELSE BEGIN
Message = DIALOG_MESSAGE("Please create R* files first",/INFORMATION)
ENDELSE   
ENDIF ELSE BEGIN
Message = DIALOG_MESSAGE("Please select either AUPE or PDS data",/INFORMATION)
ENDELSE

  END
  
  'CIE_to_sRGB' : BEGIN
;IF CIE_little_xyz_test NE 0 THEN BEGIN
progressBar = Obj_New("SHOWPROGRESS")
progressBar->Start 
CD, myoutdir
;OpenW, lun, 'Xxxxx.dat', /Get_LUN, WIDTH=250
;printF, lun, X
;Free_LUN, lun
 
  
X_colour = ((little_x*Y)/little_y)
Y_colour = Y
Z_colour = (((1 - little_x - little_y)*Y)/little_y)

print, 'X_colour =', x_colour[0]

progressBar->Update, (1)*10

size_sc = size(X_colour, /DIMENSIONS)
;print, 'size_sc = ', size_sc
w = size_sc[0]
h = size_sc[1]
;print, 'w', w
;print, 'h', h

IF w EQ h THEN BEGIN
x_val = 450
y_val = 450
ENDIF
IF w GT h THEN BEGIN
x_val = 450
y_val = FIX((FLOAT(h)/FLOAT(w)) * 450)
ENDIF
IF w LT h THEN BEGIN
x_val = FIX((FLOAT(w)/FLOAT(h)) * 450)
y_val = 450
ENDIF


progressBar->Update, (1)*10
CD, myoutdir
OpenW, lun, 'xcolour.dat', /Get_LUN, WIDTH=250
;printF, lun, x_colour
Free_LUN, lun

R = make_array(w, h)
G = make_array(w, h)
B = make_array(w, h)

Foreach element, X_colour, index do BEGIN

R[index] = (3.2404542*X_colour[index]) + (-1.5371385*Y_colour[index]) + (-0.4985314*Z_colour[index])
G[index] = (-0.9692660*X_colour[index]) + (1.8760108*Y_colour[index]) + (0.0415560*Z_colour[index])
B[index] = (0.0556434*X_colour[index]) + (-0.2040259*Y_colour[index]) + (1.0572252*Z_colour[index])

ENDFOREACH

progressBar->Update, (1)*10
;CD, myoutdir
;OpenW, lun, 'RRRRRRRRRRR.dat', /Get_LUN, WIDTH=250
;printF, lun, R
;Free_LUN, lun

R_size = Size(R, /DIMENSIONS)
G_size = Size(G, /DIMENSIONS)
B_size = Size(B, /DIMENSIONS)

;print, 'R_size = ', R_size

clipped_R = make_array(R_size)
clipped_G = make_array(G_size)
clipped_B = make_array(B_size)

FOREACH element, R, index DO BEGIN
IF element LT 0 OR element GT 1 THEN BEGIN
IF element LT 0 THEN BEGIN
clipped_R[index] = 0
ENDIF
IF element GT 1 THEN BEGIN
clipped_R[index] = 1
ENDIF
ENDIF ELSE BEGIN
clipped_R[index] = element
ENDELSE
ENDFOREACH


FOREACH element, G, index DO BEGIN
IF element LT 0 OR element GT 1 THEN BEGIN
IF element LT 0 THEN BEGIN
clipped_G[index] = 0
ENDIF
IF element GT 1 THEN BEGIN
clipped_G[index] = 1
ENDIF
ENDIF ELSE BEGIN
clipped_G[index] = element
ENDELSE
ENDFOREACH

counter = 0
counter_0 = 0
counter_1 = 0

FOREACH element, B, index DO BEGIN
IF element LT 0 OR element GT 1 THEN BEGIN
IF element LT 0 THEN BEGIN
clipped_B[index] = 0
ENDIF
IF element GT 1 THEN BEGIN
clipped_B[index] = 1
ENDIF
ENDIF ELSE BEGIN
clipped_B[index] = element
ENDELSE
ENDFOREACH

progressBar->Update, (1)*10
;print, 'counters = ', counter
;print, counter_0
;print, counter_1

;print, 'R = ',clipped_R[0:10]
;print, 'G = ', clipped_G[0:10]
;print, 'B = ', clipped_B[0:10]

;print, 'clipped size = ', size(clipped_R)

gamma_R = make_array(R_size)
gamma_G = make_array(G_size)
gamma_B = make_array(B_size)

FOREACH element, clipped_R, index DO BEGIN
IF element LT 0.0031308 OR element EQ 0.0031308 OR element GT 0.0031308 THEN BEGIN
IF element LT 0.0031308 OR element EQ 0.0031308 THEN BEGIN
gamma_R[index] = (12.92 * element)
ENDIF
IF element GT 0.0031308 THEN BEGIN
gamma_R[index] = (1.055*element^(1/2.2))
ENDIF
ENDIF ELSE BEGIN
gamma_R[index] = element
ENDELSE
ENDFOREACH

FOREACH element, clipped_G, index DO BEGIN
IF element LT 0.0031308 OR element EQ 0.0031308 OR element GT 0.0031308 THEN BEGIN
IF element LT 0.0031308 OR element EQ 0.0031308 THEN BEGIN
gamma_G[index] = (12.92 * element)
ENDIF
IF element GT 0.0031308 THEN BEGIN
gamma_G[index] = (1.055*element^(1/2.2))
ENDIF
ENDIF ELSE BEGIN
gamma_G[index] = element
ENDELSE
ENDFOREACH

FOREACH element, clipped_B, index DO BEGIN
IF element LT 0.0031308 OR element EQ 0.0031308 OR element GT 0.0031308 THEN BEGIN
IF element LT 0.0031308 OR element EQ 0.0031308 THEN BEGIN
gamma_B[index] = (12.92 * element)
ENDIF
IF element GT 0.0031308 THEN BEGIN
gamma_B[index] = (1.055*element^(1/2.2))
ENDIF
ENDIF ELSE BEGIN
gamma_B[index] = element
ENDELSE
ENDFOREACH


progressBar->Update, (1)*10
;;print, 'R = ', gamma_R[0:10]
;;print, 'G = ', gamma_G[0:10]
;;print, 'B = ', Gamma_B[0:10]

;print, 'gamma size = ', size(gamma_R)

R_complete = ROUND(gamma_R* 255)
G_complete = ROUND(gamma_G* 255)
B_complete = ROUND(gamma_B* 255)

print, 'R = ', R_complete[0:10]
print, 'G = ', G_complete[0:10]
print, 'B = ', B_complete[0:10]


    RGB=intarr(3,w,h)
    New_RGB=fltarr(3,w,h) ;Used in 'save_image' event below.
    scaled_RGB=intarr(3,w,h) ;Used in this IF statement.
    RGB[0,*,*]= R_complete
    RGB[1,*,*]= G_complete
    RGB[2,*,*]= B_complete
    scaled_RGB[0,*,*] = congrid(R_complete, w, h, /center)
    scaled_RGB[1,*,*] = congrid(G_complete, w, h, /center)
    scaled_RGB[2,*,*] = congrid(B_complete, w, h, /center)
window, 3, XSIZE=w, YSIZE=h
    TVSCL, scaled_RGB, true=1
    
    print, 'RGB[0:10] = ', RGB[0:10] 
    
    progressBar->Destroy
Obj_Destroy, progressBar
    
    myoutfile = myoutdir + 'colour_corrected.png'
     ;Scale the RGB image data from 16-bit to 8-bit. This can be read by the XROI widget.
     New_RGB[0,*,*] = (!D.table_size - 1)* (FLOAT(RGB[0,*,*] - min(RGB[0,*,*]))/FLOAT(max(RGB[0,*,*]) - min(RGB[0,*,*])))
     New_RGB[1,*,*] = (!D.table_size - 1)* (FLOAT(RGB[1,*,*] - min(RGB[1,*,*]))/FLOAT(max(RGB[1,*,*]) - min(RGB[1,*,*])))
     New_RGB[2,*,*] = (!D.table_size - 1)* (FLOAT(RGB[2,*,*] - min(RGB[2,*,*]))/FLOAT(max(RGB[2,*,*]) - min(RGB[2,*,*])))
     print, 'new_rgb[0:10] = ', new_rgb[0:10]
     write_png, myoutfile, New_RGB
;ENDIF ELSE BEGIN
;Message = DIALOG_MESSAGE("Please calculate CIE xyz first (button can be found in widget that opens up when pressing 'Generate CIE data')",/INFORMATION)
;ENDELSE
  END
  
  
  
      'Select_ROI_AUPE' : BEGIN
        IF (file[0] NE '') THEN BEGIN
        CD, myoutdir
        number_of_files=size(file,/dimension)
        image = read_png(myoutfile)
        XROI, image, r, g, b, $ REGIONS_IN = regions, $
        REGIONS_OUT = regions, $
        ROI_SELECT_COLOR = roi_select_color, $
        ROI_GEOMETRY = geometry, $
        ROI_COLOR = roi_color, REJECTED = rejected, /BLOCK
        OBJ_DESTROY, rejected
    ;    print, "geometry = ", geometry
        print, "geometry(0) = ", geometry(0)
        geo_white = geometry(0)

        
     ;   print, 'gemoetry = ', geometry.(1)
        geo = geo_white.(1)
        print, 'geo = ', geo
        geo_x = geo(0)
        geo_y = geo(1)
        print, geo(0)
        print, geo(1)
        coord_array_x = make_array(25)  ;  @@@!!!
        coord_array_y = make_array(25)
        LU_x = geo_x - 2
        LU_y = geo_y + 2
        
        first_line_x = make_array(5)
        FOR i=0, (4) DO BEGIN
        first_line_x(i) = LU_x + i
        ENDFOR
        coord_array_x(0) = first_line_x
        coord_array_x(5) = first_line_x
        coord_array_x(10) = first_line_x
        coord_array_x(15) = first_line_x
        coord_array_x(20) = first_line_x
        
        print, 'coord_array_x = ', coord_array_x
        
        FOREACH element, coord_array_x, index DO BEGIN
        IF index LE '4' THEN BEGIN
        coord_array_y[index] = LU_y
        ENDIF
        IF index GE '5' AND index LE '9' THEN BEGIN
        coord_array_y[index] = LU_y - 1
        ENDIF
        IF index GE '10' AND index LE '14' THEN BEGIN
        coord_array_y[index] = LU_y - 2
        ENDIF
        IF index GE '15' AND index LE '19' THEN BEGIN
        coord_array_y[index] = LU_y - 3
        ENDIF
        IF index GE '20' AND index LE '24' THEN BEGIN
        coord_array_y[index] = LU_y - 4
        ENDIF
        ENDFOREACH
        
        print, 'coord_array_y = ', coord_array_y

        save_x = myoutdir + 'White_region_coordinates_x.wrc'
        save_y = myoutdir + 'White_region_coordinates_y.wrc'
        Write_csv, save_x, coord_array_x
        Write_csv, save_y, coord_array_y
        
       ; roicentroid = geometry.(1)
        ;print, 'roicentroid =', roicentroid
        ;print, 'regions = ', regions
        ENDIF ELSE BEGIN
        Message = DIALOG_MESSAGE("NO AUPE DATA SELECTED",/INFORMATION)
        ENDELSE
      END
      
      'Restore_ROI_AUPE' : BEGIN
      path_in = !DIR+'/examples/data'
      savefile = DIALOG_PICKFILE(PATH=path_in, /MULTIPLE_FILES, /READ, $
      FILTER='*.sav', /FIX_FILTER)
      ;print, 'savefile = ', savefile
        IF (file[0] NE '') THEN BEGIN
        IF (savefile NE '') THEN BEGIN
        number_of_files=size(file,/dimension)
        image = read_png(myoutfile)
        RESTORE, savefile, RESTORED_OBJECTS = myRoi
        XROI, image, REGIONS_IN = myRoi, $
        ROI_GEOMETRY = geometry, $
        REJECTED = rejected, /BLOCK
        ;print, 'statistics = ', statistics
                geo_white = geometry(0)

        
     ;   print, 'gemoetry = ', geometry.(1)
        geo = geo_white.(1)
        print, 'geo = ', geo
        geo_x = geo(0)
        geo_y = geo(1)
        print, geo(0)
        print, geo(1)
        coord_array_x = make_array(25)  ;  @@@!!!
        coord_array_y = make_array(25)
        LU_x = geo_x - 2
        LU_y = geo_y + 2
        
        first_line_x = make_array(5)
        FOR i=0, (4) DO BEGIN
        first_line_x(i) = LU_x + i
        ENDFOR
        coord_array_x(0) = first_line_x
        coord_array_x(5) = first_line_x
        coord_array_x(10) = first_line_x
        coord_array_x(15) = first_line_x
        coord_array_x(20) = first_line_x
        
        print, 'coord_array_x = ', coord_array_x
        
        FOREACH element, coord_array_x, index DO BEGIN
        IF index LE '4' THEN BEGIN
        coord_array_y[index] = LU_y
        ENDIF
        IF index GE '5' AND index LE '9' THEN BEGIN
        coord_array_y[index] = LU_y - 1
        ENDIF
        IF index GE '10' AND index LE '14' THEN BEGIN
        coord_array_y[index] = LU_y - 2
        ENDIF
        IF index GE '15' AND index LE '19' THEN BEGIN
        coord_array_y[index] = LU_y - 3
        ENDIF
        IF index GE '20' AND index LE '24' THEN BEGIN
        coord_array_y[index] = LU_y - 4
        ENDIF
        ENDFOREACH
        
        print, 'coord_array_y = ', coord_array_y

        save_x = myoutdir + 'White_region_coordinates_x.wrc'
        save_y = myoutdir + 'White_region_coordinates_y.wrc'
        Write_csv, save_x, coord_array_x
        Write_csv, save_y, coord_array_y
        
        ENDIF ELSE BEGIN
        Message = DIALOG_MESSAGE("NO ROI DATA SELECTED",/INFORMATION)
        ENDELSE
        ENDIF ELSE BEGIN
        Message = DIALOG_MESSAGE("NO AUPE DATA SELECTED",/INFORMATION)
        ENDELSE      
      END
      
      'Get_Stats': BEGIN
      path_in = !DIR+'/examples/data'
      file2 = DIALOG_PICKFILE(PATH=path_in, /MULTIPLE_FILES, /READ, $
      FILTER='*.png', /FIX_FILTER)
        IF (file2[0] NE '') THEN BEGIN
        IF (savefile NE '') THEN BEGIN
        number_of_files_stats=size(file2,/dimension)
        stat_test = 1
        length_dir = strlen(myoutdir)
        filter_number = make_array(1, number_of_files_stats, /STRING)
          FOREACH element, file2, index DO BEGIN
          ;print, 'element = ', element
            IF (strlen(element) EQ (length_dir + 6)) OR (strlen(element) EQ (length_dir + 7)) THEN BEGIN
              IF (strlen(element) EQ (length_dir + 6)) THEN BEGIN
              ;print, 'index = ', index
              filter_number[index] = strmid(element, length_dir, 6)
              ENDIF
              IF (strlen(element) EQ (length_dir + 7)) THEN BEGIN
              ;print, 'index = ', index
              filter_number[index] = strmid(element, length_dir, 7)
              ENDIF
            ENDIF ELSE BEGIN
            message = DIALOG_MESSAGE("Please make sure that your images follow the naming convention of 'f1.png', 'f2.png', etc and that no image name is greater than f99", /INFORMATION)
            ENDELSE
          ENDFOREACH
        ;print, 'filter_number = ', filter_number
        y_reflectance = make_array(9, number_of_files_stats, /FLOAT)
        y_standard_deviation = make_array(9, number_of_files_stats, /FLOAT)
        ;;;Beginning of progress bar code A;;;
        progressBar = Obj_New("SHOWPROGRESS")
        progressBar->Start
        ;;;End of progress bar code A;;;
        white_data = []

 neutral_44_data = []
neutral_70_data = []
  neutral_1_05_data =[] 
   black_data = []
   blue_data = []
   green_data = []
   red_data = []
   yellow_data = []
          FOR i=0, (number_of_files_stats[0] - 1) DO BEGIN
          image = read_png(file2[i])
          RESTORE, savefile, RESTORED_OBJECTS = myRoi
          XROI_E, image, REGIONS_IN = myRoi, GROUP = death, $
          STATISTICS = statistics, $
          MASKPIXELVALUES0 = maskpixelvalues0, $
          MASKPIXELVALUES1 = maskpixelvalues1, $
          MASKPIXELVALUES2 = maskpixelvalues2, $
          MASKPIXELVALUES3 = maskpixelvalues3, $
          MASKPIXELVALUES4 = maskpixelvalues4, $
          MASKPIXELVALUES5 = maskpixelvalues5, $
          MASKPIXELVALUES6 = maskpixelvalues6, $
          MASKPIXELVALUES7 = maskpixelvalues7, $
          MASKPIXELVALUES8 = maskpixelvalues8, $
          ROI_GEOMETRY = geometry, $
          REJECTED = rejected, $
          /BLOCK
          FOREACH element, maskpixelvalues0, index DO BEGIN        
          IF maskpixelvalues0(index) THEN white_data = [white_data, element]        
          ENDFOREACH        
          
          FOREACH element, maskpixelvalues1, index DO BEGIN        
          IF maskpixelvalues1(index) THEN neutral_44_data = [neutral_44_data, element]        
          ENDFOREACH    
          
          FOREACH element, maskpixelvalues2, index DO BEGIN        
          IF maskpixelvalues2(index) THEN neutral_70_data = [neutral_70_data, element]        
          ENDFOREACH    

          FOREACH element, maskpixelvalues3, index DO BEGIN        
          IF maskpixelvalues3(index) THEN neutral_1_05_data = [neutral_1_05_data, element]        
          ENDFOREACH    

          FOREACH element, maskpixelvalues4, index DO BEGIN        
          IF maskpixelvalues4(index) THEN black_data = [black_data, element]        
          ENDFOREACH    

          FOREACH element, maskpixelvalues5, index DO BEGIN        
          IF maskpixelvalues5(index) THEN blue_data = [blue_data, element]        
          ENDFOREACH    

          FOREACH element, maskpixelvalues6, index DO BEGIN        
          IF maskpixelvalues6(index) THEN green_data = [green_data, element]        
          ENDFOREACH   
          
          FOREACH element, maskpixelvalues7, index DO BEGIN        
          IF maskpixelvalues7(index) THEN red_data = [red_data, element]        
          ENDFOREACH              

          FOREACH element, maskpixelvalues8, index DO BEGIN        
          IF maskpixelvalues8(index) THEN yellow_data = [yellow_data, element]        
          ENDFOREACH    
         ; white_data = white_data + maskpixelvalues0
          print, 'white_data_nonono = ', white_data
          ;maskpixelvalues0_new = maskpixelvalues0_new + maskpixelvalues0
                    ;          WIDGET_CONTROL, XROI, /destroy destroys the widgettt.. not xroi though...
          ;print, 'statistics = ', statistics
          average = statistics.(3)
          standard_deviation = statistics.(4)
          ;print, 'average', average
          ;print, 'standard deviation = ', standard_deviation
          ;print, 'i =', i
          j = i*9
          y_reflectance [j] = average
          y_standard_deviation [j] = standard_deviation
          ;print, 'y_reflectance', y_reflectance
          ;print, 'y_standard_deviation = ', y_standard_deviation
          progressBar->Update, (i+1)*10
          ENDFOR
          print, 'white_data = ', white_data
        progressBar->Destroy
        Obj_Destroy, progressBar
        ENDIF ELSE BEGIN
        Message = DIALOG_MESSAGE("NO ROI DATA SELECTED",/INFORMATION)
        ENDELSE
        ENDIF ELSE BEGIN
        Message = DIALOG_MESSAGE("NO R* DATA SELECTED",/INFORMATION)
        ENDELSE
      END
      
      'Calculate_Radiance_per_sec' : BEGIN
      IF savefile NE '' THEN BEGIN
      IF (file2[0] NE '') THEN BEGIN
      progressBar = Obj_New("SHOWPROGRESS")
      progressBar->Start
      exposure_array = make_array(1, number_of_files_stats, /FLOAT)
      H=FLTARR(1,1)
      progressBar->Update, (1)*30
      spawn_all_array = make_array(number_of_files_stats, /string)
      print, 'filter_number = ', filter_number
        FOREACH element, filter_number, index DO BEGIN
        spawn_filter = 'identify -format "%[AU_exposureTime]\n" ' + element + ' > l-shut.dat'
        ;spawn_all_array[index] = element
        ;print, 'spawn_filter = ', spawn_filter
        ;print, 'myoutdir = ', myoutdir
        CD, (myoutdir)
        SPAWN, spawn_filter
        filename = 'l-shut.dat'
        OPENR, 8, filename 
        READF,8,H
        ;print, 'H = ', H
        exposure_array[index] = H
        CLOSE,8 
        spawn_all_array[index] = strcompress(STRING(H), /REMOVE_ALL)
        ENDFOREACH
        spawn_all = '(echo ' 
        FOR i = 0, (number_of_files_stats[0] - 1) DO BEGIN
        spawn_all = spawn_all + spawn_all_array[i] + ' && echo '
        ENDFOR
        str_len = strlen(spawn_all)
        spawn_all = strmid(spawn_all, 0, str_len - 9)
        ;print, 'spawn_all = ', spawn_all
       spawn_all = spawn_all + ') > all_exposure.dat'
        CD, (myoutdir) 
      SPAWN, spawn_all
        progressBar->Update, (1)*30
      ;print, 'exposure at end = ', exposure_array
      radiance_per_sec = make_array(9, number_of_files_stats)
        FOREACH element, y_reflectance, index DO BEGIN
        radiance_per_sec[index] = element / exposure_array[(index/9)]
        ;print, 'radiance per sec = ', radiance_per_sec
        ENDFOREACH
        progressBar->Update, (1)*30
      ;print, 'radiance per sec at end = ', radiance_per_sec
      progressBar->Destroy
      Obj_Destroy, progressBar
      Stereo = 'N'
      ENDIF ELSE BEGIN
        Message = DIALOG_MESSAGE("NO R* DATA SELECTED PLEASE CALCULATE STATISTICS FIRST",/INFORMATION)
      ENDELSE
      ENDIF ELSE BEGIN
        Message = DIALOG_MESSAGE("NO ROI DATA SELECTED",/INFORMATION)
      ENDELSE
      END
      
      'left_or_right' : BEGIN
      WIDGET_CONTROL, ev.VALUE, GET_UVALUE=bgroup2id
      ;print, 'bgroup2id = ', bgroup2id
        IF bgroup2id EQ 0 OR bgroup2id EQ 1 THEN BEGIN
          IF bgroup2id EQ 0 THEN BEGIN
          Stereo = 'LWAC'
          ENDIF
          IF bgroup2id EQ 1 THEN BEGIN
          Stereo = 'RWAC'
          ENDIF
        ENDIF ELSE BEGIN
        Message = DIALOG_MESSAGE("Something has gone wrong, please restart the program",/INFORMATION)
        ENDELSE
        ;print, 'stereo = ', stereo
      END
      
      'left_or_right_or_both' : BEGIN
      WIDGET_CONTROL, ev.VALUE, GET_UVALUE=bgroup2id
      ;print, 'bgroup2id = ', bgroup2id
        IF bgroup2id EQ 0 OR bgroup2id EQ 1 OR bgroup2id EQ 2 THEN BEGIN
          IF bgroup2id EQ 0 THEN BEGIN
          Stereo = 'LWAC'
          ENDIF
          IF bgroup2id EQ 1 THEN BEGIN
          Stereo = 'RWAC'
          ENDIF
          IF bgroup2id EQ 2 THEN BEGIN
          Stereo = 'Both'
          ENDIF
          print, 'stereo = ', stereo
        ENDIF ELSE BEGIN
        Message = DIALOG_MESSAGE("Something has gone wrong, please restart the program",/INFORMATION)
        ENDELSE
        ;print, 'stereo = ', stereo
      END
      
      
            'roi_colours' : BEGIN 
      WIDGET_CONTROL, ev.VALUE, GET_UVALUE=bgroup3id
   ;   print, 'bgroup3id = ', bgroup3id
       ; IF bgroup2id EQ 0 OR bgroup2id EQ 1 THEN BEGIN
       ;if it's 0 it's ticked, if it's 1 it's unticked
       colour_array = make_array(9)
          IF bgroup3id EQ 0 THEN BEGIN
          white = white + 1
          white=evenodd(white)
          colour_array[0] = white
          ENDIF
          IF bgroup3id EQ 1 THEN BEGIN
          neutral_44 = neutral_44 + 1
          neutral_44=evenodd(neutral_44)
          colour_array[1] = neutral_44
          ENDIF
          IF bgroup3id EQ 2 THEN BEGIN
          neutral_70 = neutral_70 + 1
          neutral_70=evenodd(neutral_70)
          colour_array[2] = neutral_70
          ENDIF
          IF bgroup3id EQ 3 THEN BEGIN
          neutral_1_05 = neutral_1_05 + 1
          neutral_1_05=evenodd(neutral_1_05)
          colour_array[3] = neutral_1_05
          ENDIF
          IF bgroup3id EQ 4 THEN BEGIN
          black = black + 1
          black=evenodd(black)
          colour_array[4] = black
          ENDIF
          IF bgroup3id EQ 5 THEN BEGIN
          blue = blue + 1
          blue=evenodd(blue)
          colour_array[5] = blue
          ENDIF
          IF bgroup3id EQ 6 THEN BEGIN
          green = green + 1
          green=evenodd(green)
          colour_array[6] = green
          ENDIF
          IF bgroup3id EQ 7 THEN BEGIN
          red = red + 1
          red=evenodd(red)
          colour_array[7] = red
          ENDIF
          IF bgroup3id EQ 8 THEN BEGIN
          yellow = yellow + 1
          yellow=evenodd(yellow)
          colour_array[8] = yellow
          ENDIF 
          
          print, 'colour_array', colour_array       
       ; ENDIF ELSE BEGIN
       ; Message = DIALOG_MESSAGE("Something has gone wrong, please restart the program",/INFORMATION)
       ; ENDELSE
        ;print, 'stereo = ', stereo
      END
      
      
      'Calculate_offset_and_slope_small' : BEGIN
      IF savefile NE '' THEN BEGIN
      IF (file2(0) NE '') THEN BEGIN
        IF stat_test EQ 1 THEN BEGIN
        IF (radiance_per_sec[0] NE '') THEN BEGIN
          IF Stereo EQ 'LWAC' OR Stereo EQ 'RWAC' THEN BEGIN
          progressBar = Obj_New("SHOWPROGRESS")
          progressBar->Start
          B = WHERE(colour_array LT 1, count = count_colour) ;;;;;;;!!!!!!
          print, 'count_colour = ', count_colour
          lab_measured_array = make_array(9, number_of_files_stats)
          lab_measured_names = StrArr(number_of_files_stats)
        ;  CD, directory
            IF Stereo EQ 'LWAC' THEN BEGIN
              FOREACH element, Filter_number, index DO BEGIN
                IF element EQ 'f1.png' OR element EQ 'f2.png' OR element EQ 'f3.png' OR element EQ 'f10.png' OR element EQ 'f11.png' OR element EQ 'f12.png' OR element EQ 'f4.png' OR element EQ 'f5.png' OR element EQ 'f6.png' OR element EQ 'f7.png' OR element EQ 'f8.png' OR element EQ 'f9.png' OR element EQ 'f01.png' OR element EQ 'f02.png' OR element EQ 'f03.png' OR element EQ 'f04.png' OR element EQ 'f05.png' OR element EQ 'f06.png' OR element EQ 'f07.png' OR element EQ 'f08.png' OR element EQ 'f09.png' THEN BEGIN
                  IF element EQ 'f1.png' OR element EQ 'f2.png' OR element EQ 'f3.png' OR element EQ 'f01.png' OR element EQ 'f02.png' OR element EQ 'f03.png' THEN BEGIN
                  Message = DIALOG_MESSAGE("No data available for broadband filters (f1, f2, f3)",/INFORMATION)
                  ENDIF
                  IF element EQ 'f10.png' OR element EQ 'f11.png' OR element EQ 'f12.png' THEN BEGIN
                  Message = DIALOG_MESSAGE("No data available for filters f10 and higher",/INFORMATION)
                  ENDIF
                  CD, img_dir
                  IF element EQ 'f4.png' OR element EQ 'f04.png' THEN BEGIN
                  restore, 'LWAC_Lab.sav'
                  ;wavelength_438 = READ_SYLK("LWAC_Lab.slk", /ARRAY, /COLMAJOR, $
                  ;STARTROW = 2, STARTCOL = 1, NCOLS = 9, NROWS = 1) ; /USEDOUBLES) ;/USELONGS)
                  ;print, 'wavelength_438 = ', wavelength_438
                  lab_measured_array[0,index] = wave
                  lab_measured_names[index] = 'Lab measured vs image at wavelength 438'
                  ENDIF
                  IF element EQ 'f5.png' OR element EQ 'f05.png' THEN BEGIN
                  restore, 'LWAC_Lab_2.sav'
                  ;wavelength_500 = READ_SYLK("LWAC_Lab.slk", /ARRAY, /COLMAJOR, $
                  ;STARTROW = 3, STARTCOL = 1, NCOLS = 9, NROWS = 1) ; /USEDOUBLES) ;/USELONGS)
                  ;print, 'wavelength_500 = ', wavelength_500
                  lab_measured_array[0,index] = wave2;wavelength_500
                  lab_measured_names[index] = 'Lab measured vs image at wavelength 500'
                  ENDIF
                  IF element EQ 'f6.png' OR element EQ 'f06.png' THEN BEGIN
                  restore, 'LWAC_Lab_3.sav'
                  ;wavelength_532 = READ_SYLK("LWAC_Lab.slk", /ARRAY, /COLMAJOR, $
                  ;STARTROW = 4, STARTCOL = 1, NCOLS = 9, NROWS = 1) ; /USEDOUBLES) ;/USELONGS)
                  ;print, 'wavelength_532 = ', wavelength_532
                  lab_measured_array[0,index] = wave3;wavelength_532
                  lab_measured_names[index] = 'Lab measured vs image at wavelength 532'
                  ENDIF
                  IF element EQ 'f7.png' OR element EQ 'f07.png' THEN BEGIN
                  restore, 'LWAC_Lab_4.sav'
                  ;wavelength_568 = READ_SYLK("LWAC_Lab.slk", /ARRAY, /COLMAJOR, $
                  ;STARTROW = 5, STARTCOL = 1, NCOLS = 9, NROWS = 1) ; /USEDOUBLES) ;/USELONGS)
                  ;print, 'wavelength_568 = ', wavelength_568
                  lab_measured_array[0,index] = wave4;wavelength_568
                  lab_measured_names[index] = 'Lab measured vs image at wavelength 568'
                  ENDIF
                  IF element EQ 'f8.png' OR element EQ 'f08.png' THEN BEGIN
                  restore, 'LWAC_Lab_5.sav'
                  ;wavelength_610 = READ_SYLK("LWAC_Lab.slk", /ARRAY, /COLMAJOR, $
                  ;STARTROW = 6, STARTCOL = 1, NCOLS = 9, NROWS = 1) ; /USEDOUBLES) ;/USELONGS)
                  ;print, 'wavelength_610 = ', wavelength_610
                  lab_measured_array[0,index] = wave5;wavelength_610
                  lab_measured_names[index] = 'Lab measured vs image at wavelength 610'
                  ENDIF
                  IF element EQ 'f9.png' OR element EQ 'f09.png' THEN BEGIN
                  restore, 'LWAC_Lab_6.sav'
                  ;wavelength_671 = READ_SYLK("LWAC_Lab.slk", /ARRAY, /COLMAJOR, $
                  ;STARTROW = 7, STARTCOL = 1, NCOLS = 9, NROWS = 1) ; /USEDOUBLES) ;/USELONGS)
                  ;print, 'wavelength_571 = ', wavelength_671
                  lab_measured_array[0,index] = wave6;wavelength_671
                  lab_measured_names[index] = 'Lab measured vs image at wavelength 671'
                  ENDIF
                ENDIF ELSE BEGIN
                Message = DIALOG_MESSAGE("Please only use filters f1 to f12",/INFORMATION)
                ENDELSE
              ENDFOREACH
            ;print, 'lab_measured_array= ', lab_measured_array
            ENDIF
    
            IF Stereo EQ 'RWAC' THEN BEGIN
              FOREACH element, Filter_number, index DO BEGIN
                IF element EQ 'f1.png' OR element EQ 'f2.png' OR element EQ 'f3.png' OR element EQ 'f10.png' OR element EQ 'f11.png' OR element EQ 'f12.png' OR element EQ 'f4.png' OR element EQ 'f5.png' OR element EQ 'f6.png' OR element EQ 'f7.png' OR element EQ 'f8.png' OR element EQ 'f9.png' OR element EQ 'f01.png' OR element EQ 'f02.png' OR element EQ 'f03.png' OR element EQ 'f04.png' OR element EQ 'f05.png' OR element EQ 'f06.png' OR element EQ 'f07.png' OR element EQ 'f08.png' OR element EQ 'f09.png' THEN BEGIN
                  IF element EQ 'f1.png' OR element EQ 'f2.png' OR element EQ 'f3.png' OR element EQ 'f01.png' OR element EQ 'f02.png' OR element EQ 'f03.png' THEN BEGIN
                  Message = DIALOG_MESSAGE("No data available for broadband filters (f1, f2, f3)",/INFORMATION)
                  ENDIF
                  IF element EQ 'f10.png' OR element EQ 'f11.png' OR element EQ 'f12.png' THEN BEGIN
                  Message = DIALOG_MESSAGE("No data available for filters f10 and higher",/INFORMATION)
                  ENDIF
                  CD, img_dir
                  IF element EQ 'f4.png' OR element EQ 'f04.png' THEN BEGIN
                  restore, 'RWAC_Lab_7.sav'
                  ;wavelength_740 = READ_SYLK("RWAC_Lab.slk", /ARRAY, /COLMAJOR, $
                  ;STARTROW = 2, STARTCOL = 1, NCOLS = 9, NROWS = 1)
                  ;print, 'wavelength_740 = ', wavelength_740
                  lab_measured_array[0,index] = wave7;wavelength_740
                  lab_measured_names[index] = 'Lab measured vs image at wavelength 740'
                  ENDIF
                  IF element EQ 'f5.png' OR element EQ 'f05.png' THEN BEGIN
                  restore, 'RWAC_Lab_8.sav'
                 ; wavelength_780 = READ_SYLK("RWAC_Lab.slk", /ARRAY, /COLMAJOR, $
                 ; STARTROW = 3, STARTCOL = 1, NCOLS = 9, NROWS = 1) 
                  ;print, 'wavelength_780 = ', wavelength_780
                  lab_measured_array[0,index] = wave8;wavelength_780
                  lab_measured_names[index] = 'Lab measured vs image at wavelength 780'
                  ENDIF
                  IF element EQ 'f6.png' OR element EQ 'f06.png' THEN BEGIN
                  restore, 'RWAC_Lab_9.sav'
                  ;wavelength_832 = READ_SYLK("RWAC_Lab.slk", /ARRAY, /COLMAJOR, $
                  ;STARTROW = 4, STARTCOL = 1, NCOLS = 9, NROWS = 1) 
                  ;print, 'wavelength_832 = ', wavelength_832
                  lab_measured_array[0,index] = wave9;wavelength_832
                  lab_measured_names[index] = 'Lab measured vs image at wavelength 832'
                  ENDIF
                  IF element EQ 'f7.png' OR element EQ 'f07.png' THEN BEGIN
                  restore, 'RWAC_Lab_10.sav'
                  ;wavelength_900 = READ_SYLK("RWAC_Lab.slk", /ARRAY, /COLMAJOR, $
                  ;STARTROW = 5, STARTCOL = 1, NCOLS = 9, NROWS = 1) 
                  ;print, 'wavelength_900 = ', wavelength_900
                  lab_measured_array[0,index] = wave10;wavelength_900
                  lab_measured_names[index] = 'Lab measured vs image at wavelength 900'
                  ENDIF
                  IF element EQ 'f8.png' OR element EQ 'f08.png' THEN BEGIN
                  restore, 'RWAC_Lab_11.sav'
                  ;wavelength_950 = READ_SYLK("RWAC_Lab.slk", /ARRAY, /COLMAJOR, $
                  ;STARTROW = 6, STARTCOL = 1, NCOLS = 9, NROWS = 1) 
                  ;print, 'wavelength_950 = ', wavelength_950
                  lab_measured_array[0,index] = wave11;wavelength_950
                  lab_measured_names[index] = 'Lab measured vs image at wavelength 950'
                  ENDIF 
                  IF element EQ 'f9.png' OR element EQ 'f09.png' THEN BEGIN
                  restore, 'RWAC_Lab_12.sav'
                  ;wavelength_1000 = READ_SYLK("RWAC_Lab.slk", /ARRAY, /COLMAJOR, $
                  ;STARTROW = 7, STARTCOL = 1, NCOLS = 9, NROWS = 1)
                  ;print, 'wavelength_1000 = ', wavelength_1000
                  lab_measured_array[0,index] = wave12;wavelength_1000
                  lab_measured_names[index] = 'Lab measured vs image at wavelength 1000'
                  ENDIF 
                ENDIF ELSE BEGIN
                Message = DIALOG_MESSAGE("Please only use filters f1 to f12",/INFORMATION)
                ENDELSE
              ENDFOREACH
            ENDIF
          zero_array = [0]
          progressBar->Update, (1)*30
            FOR i=0, (number_of_files_stats[0] - 1) DO BEGIN
            ;print, 'lab_measured_array[0,i] = ', lab_measured_array[*, i]
            ;print, 'radiance_per_sec[0,i] = ', radiance_per_sec[*, i]
            ;print, 'lab_measured_names[i] = ', lab_measured_names[i]
            window, i
            PLOT, lab_measured_array[*,i], radiance_per_sec[*,i], psym = 7, TITLE=lab_measured_names[i]
            Result = LINFIT( lab_measured_array[*, i], radiance_per_sec[*, i], CHISQ=chisq, /DOUBLE, PROB=prob) 
            ;print, 'Result = ', Result
            ;print, 'chisq = ', chisq
            ;print, 'prob = ', prob
            offset = result(0)
            slope = result(1)
            ;print, 'A = ', offset
            ;print, 'B = ', slope
            size_array = size(lab_measured_array[*, i])
            ;print, 'size_array = ', size_array
            size_whole = (size_array(1) + 1)
            ;print, 'size_whole = ', size_whole
            new_array = make_array(size_whole, 1)
            new_array[0] = 0
            array = lab_measured_array[*, i]
              foreach element, array, index do begin
              new_array[index + 1] = element
              endforeach
              ;print, 'new_array = ', new_array
              y_array = make_array(10, 1)
              foreach element, new_array, index do begin
              y_array[index] = (offset + (element*slope))
              endforeach
            ;print, 'y_array = ', y_array
            oplot, new_array, y_array, linestyle=0
            lab_name = lab_measured_names[i]
            ;print, 'lab name = ', lab_name
            size_lab = strlen(lab_name)
            ;print, 'size_lab = ', size_lab
              IF size_lab EQ 39 THEN BEGIN
              wavelength_number = strmid(lab_name, 36, 3)
              ENDIF
              IF size_lab EQ 40 THEN BEGIN
              wavelength_number = strmid(lab_name, 36, 4)
              ENDIF
 ;           make_folder = 'mkdir wavelength_' + wavelength_number
 ;           folder_name = 'wavelength_' + wavelength_number
            ;print, 'make_folder =', make_folder
 ;           CD, (myoutdir)
 ;           SPAWN, make_folder
 ;           myoutdir_new = myoutdir + folder_name
            CD, (myoutdir)
            string_offset = strcompress(STRING(offset), /REMOVE_ALL)
            ;print, 'string_offset = ', string_offset
            string_slope = strcompress(STRING(slope), /REMOVE_ALL)
            wavelength_file = 'radiometric_scaling_factor_wavelength_' + wavelength_number + '.dat'
            print, 'wavelength_file = ', wavelength_file
            ;print, 'string_slope = ', string_slope
            create_text_file =  '(echo ' + string_offset + ' && echo ' + string_slope + ') > ' + wavelength_file
            ;print, 'create_text_file = ', create_text_file
            SPAWN, create_text_file
            progressBar->Update, (i+1)*10
            ENDFOR
            myoutdir_exp = myoutdir + 'all_exposure.dat'
            myoutdir_slp_1 = myoutdir + 'radiometric_scaling_factor_wavelength_438.dat'
            myoutdir_slp_2 = myoutdir + 'radiometric_scaling_factor_wavelength_740.dat'
            search_exp = file_search(myoutdir_exp, count = count_exp)
            search_slp_1 = file_search(myoutdir_slp_1, count = count_slp_1)
            search_slp_2 = file_search(myoutdir_slp_2, count = count_slp_2)
            print, 'count_slp_1 = ', count_slp_1
            print, 'count_slp_2 = ', count_slp_2
            print, 'count_exp = ', count_exp
            progressBar->Destroy
            Obj_Destroy, progressBar 
          ENDIF ELSE BEGIN
          Message = DIALOG_MESSAGE("Please select which camera the image is from (LWAC or RWAC)",/INFORMATION)
          ENDELSE
      ENDIF ELSE BEGIN
        Message = DIALOG_MESSAGE("PLEASE CALCULATE RADIANCE PER SECOND FIRST",/INFORMATION)
      ENDELSE
        ENDIF ELSE BEGIN
        Message = DIALOG_MESSAGE("Please calculate the statistics first",/INFORMATION)
        ENDELSE
      ENDIF ELSE BEGIN
        Message = DIALOG_MESSAGE("NO R* DATA SELECTED PLEASE CALCULATE STATISTICS FIRST",/INFORMATION)
      ENDELSE
      ENDIF ELSE BEGIN
        Message = DIALOG_MESSAGE("NO ROI DATA SELECTED",/INFORMATION)
      ENDELSE
      END
     
     
     
          'Select_ROI_PDS' : BEGIN
            IF (file[0] NE '') THEN BEGIN
            IF rstar_check EQ 1 THEN BEGIN
             L_or_R = ''
             count_l = ''
             ENDIF
            myoutdir_lwac = myoutdir
            file_select_lwac = ''
            myoutfile_lwac = myoutfile
            IF L_or_R EQ 'RWAC' THEN BEGIN
            IF count_L NE '' THEN BEGIN
            dir_length = strpos(myoutfile_O, '\', /reverse_search)
            myoutdir_lwac = strmid(myoutfile_O, 0, dir_length + 1)
            ENDIF
            CD, (myoutdir_lwac)
            number_of_files=size(file,/dimension)
            myoutfile_lwac = myoutfile
            IF L_or_R EQ 'RWAC' THEN BEGIN
            IF count_L NE '' THEN BEGIN
            myoutfile_lwac = myoutfile_O
            ENDIF
            ENDIF
            IF count_L EQ '' THEN BEGIN
            CD, myoutdir
            file_select_lwac = DIALOG_PICKFILE(/MULTIPLE_FILES, /READ, $
            FILTER='*.png', /FIX_FILTER)
            IF (file_select_lwac[0] NE '') THEN BEGIN
                IF (SIZE(file_select_lwac, /N_ELEMENTS) EQ 3 OR SIZE(file_select_lwac, /N_ELEMENTS) EQ 1) THEN BEGIN
    dir_length = strpos(file_select_lwac[0], '\', /reverse_search)
    myoutdir = strmid(file_select_lwac[0], 0, dir_length + 1)
    
    progressBar = Obj_New("SHOWPROGRESS")
    progressBar->Start

      IF (SIZE(file_select_lwac, /N_ELEMENTS) EQ 3) THEN BEGIN
     
      myimg_0 = read_png(file_select_lwac[0]) 
      myimg_1 = read_png(file_select_lwac[1]) 
      myimg_2 = read_png(file_select_lwac[2])
       
      s=size(myimg_0,/dimension)
   ;   ;print, 's = ', s
      RGB=intarr(3,s[0],s[1])
      New_RGB=fltarr(3,s[0],s[1]) ;Used in 'save_image' event below.
    
      RGB[0,*,*]= myimg_0
      RGB[1,*,*]= myimg_1
      RGB[2,*,*]= myimg_2
      
    ;  ;print, 'myoutdir =', myoutdir
       ;The following string manipulation functions extract which filtered images have been selected,
      ;and create a filename with these values.
      length_all = make_array(1, 3, /INTEGER)
      length0 = strlen(file_select_lwac[0])
      length1 = strlen(file_select_lwac[1])
      length2 = strlen(file_select_lwac[2])
      length_all [0] = length0
      length_all [1] = length1
      length_all [2] = length2
      max_length = max(length_all)
     ; ;print, 'max length = ', max_length
        IF (max_length EQ (dir_length + 8) OR max_length EQ (dir_length + 7)) THEN BEGIN
          IF (max_length EQ (dir_length + 8)) THEN BEGIN
            IF length0 EQ max_length THEN BEGIN
            filter_no_1 = strmid(file_select_lwac[0], (max_length - 7), 3)
            ENDIF ELSE BEGIN
            filter_no_1 = strmid(file_select_lwac[0], (max_length - 7), 2)
            ENDELSE
            IF length1 EQ max_length THEN BEGIN
            filter_no_2 = strmid(file_select_lwac[1], (max_length - 7), 3)
            ENDIF ELSE BEGIN
            filter_no_2 = strmid(file_select_lwac[1], (max_length - 7), 2)
            ENDELSE
            IF length2 EQ max_length THEN BEGIN
            filter_no_3 = strmid(file_select_lwac[2], (max_length - 7), 3)
            ENDIF ELSE BEGIN
            filter_no_3 = strmid(file_select_lwac[2], (max_length - 7), 2)
            ENDELSE
            ENDIF
            IF (max_length EQ (dir_length + 7)) THEN BEGIN
            filter_no_1 = strmid(file_select_lwac[0], (max_length - 6), 2)
            filter_no_2 = strmid(file_select_lwac[1], (max_length - 6), 2)
            filter_no_3 = strmid(file_select_lwac[2], (max_length - 6), 2)  
            ENDIF 
      progressBar->Update, (1)*50
            IF (max_length EQ (dir_length + 8)) THEN BEGIN
              IF length0 EQ length1 AND length1 EQ length2 THEN BEGIN
              myoutfile = 'RGB-   -   -   .png'
              strput, myoutfile, filter_no_1, 4
              strput, myoutfile, filter_no_2, 8
              strput, myoutfile, filter_no_3, 12
              ENDIF
              IF length0 GT length1 AND length0 GT length2 THEN BEGIN
              myoutfile = 'RGB-   -  -  .png'
              strput, myoutfile, filter_no_1, 4
              strput, myoutfile, filter_no_2, 8
              strput, myoutfile, filter_no_3, 11
              ENDIF
              IF length1 GT length0 AND length1 GT length2 THEN BEGIN
              myoutfile = 'RGB-  -   -  .png'
              strput, myoutfile, filter_no_1, 4
              strput, myoutfile, filter_no_2, 7
              strput, myoutfile, filter_no_3, 11
              ENDIF
              IF length2 GT length0 AND length2 GT length1 THEN BEGIN
              myoutfile = 'RGB-  -  -   .png'
              strput, myoutfile, filter_no_1, 4
              strput, myoutfile, filter_no_2, 7
              strput, myoutfile, filter_no_3, 10
              ENDIF
              IF length0 EQ length1 AND length0 GT length2 THEN BEGIN
              myoutfile = 'RGB-   -   -  .png'
              strput, myoutfile, filter_no_1, 4
              strput, myoutfile, filter_no_2, 8
              strput, myoutfile, filter_no_3, 12    
              ENDIF
              IF length1 EQ length2 AND length1 GT length0 THEN BEGIN
              myoutfile = 'RGB-  -   -   .png'
              strput, myoutfile, filter_no_1, 4
              strput, myoutfile, filter_no_2, 7
              strput, myoutfile, filter_no_3, 11
              ENDIF
              IF length0 EQ length2 AND length0 GT length1 THEN BEGIN
              myoutfile = 'RGB-   -  -   .png'
              strput, myoutfile, filter_no_1, 4
              strput, myoutfile, filter_no_2, 8
              strput, myoutfile, filter_no_3, 11
              ENDIF
            ENDIF
              IF (max_length EQ (dir_length + 7)) THEN BEGIN
              myoutfile = 'RGB-  -  -  .png'
              strput, myoutfile, filter_no_1, 4
              strput, myoutfile, filter_no_2, 7
              strput, myoutfile, filter_no_3, 10
              ENDIF
          dir_length = strpos(file_select_lwac[0], '\', /reverse_search)
     ;     ;print, 'dir_length =', dir_length
          myoutdir = strmid(file_select_lwac[0], 0, dir_length + 1)
     ;     ;print, 'myoutdir =', myoutdir
          myoutfile_rwac = myoutdir + myoutfile
     ;     ;print, 'myoutfile = ', myoutfile
          ;Scale the RGB image data from 16-bit to 8-bit. This can be read by the XROI widget.
          New_RGB[2,*,*] = (!D.table_size - 1)* (FLOAT(RGB[0,*,*] - min(RGB[0,*,*]))/FLOAT(max(RGB[0,*,*]) - min(RGB[0,*,*])))
          New_RGB[1,*,*] = (!D.table_size - 1)* (FLOAT(RGB[1,*,*] - min(RGB[1,*,*]))/FLOAT(max(RGB[1,*,*]) - min(RGB[1,*,*])))
          New_RGB[0,*,*] = (!D.table_size - 1)* (FLOAT(RGB[2,*,*] - min(RGB[2,*,*]))/FLOAT(max(RGB[2,*,*]) - min(RGB[2,*,*])))
          
          write_png, myoutfile_lwac, new_RGB
          print, 'myoutfile_lwac = ', myoutfile_lwac
          
  ;        ;print, 'myoutfile new = ', myoutfile
          ENDIF ELSE BEGIN
          message = DIALOG_MESSAGE("THIS IMAGE HAS NOT BEEN SAVED. Please make sure that your images follow the naming convention of 'f1.png', 'f2.png', etc and that no image name is greater than f99", /INFORMATION)
          ENDELSE
        ENDIF
          IF (SIZE(file_select_lwac, /N_ELEMENTS) EQ 1) THEN BEGIN
          myimg_0 = read_png(file_select_lwac[0]) ; /silent) ;/noscale)
          dir_length = strpos(file_select_lwac[0], '\', /reverse_search)
     ;     ;print, 'dir_length =', dir_length
          myoutdir = strmid(file_select_lwac[0], 0, dir_length + 1)
          
      ;    ;print, 'myoutdir =', myoutdir
          length = strlen(file_select_lwac[0])
          s1=size(file_select_lwac,/dimension)
          ;Create a new string array for the output file path and assign 'myinfile'.
     ;     ;print, 'myoutdir = ', myoutdir
          lengthdir = strlen(myoutdir)
  ;        ;print, 'lengthdir = ', lengthdir
          myoutfile = strarr(1)       
          myoutfile[*] = file_select_lwac[0]
          lengthfile = strlen(myoutfile)
          
   ;       ;print, 'lengthfile = ', lengthfile
    ;      ;print, 'myoutfile = ', myoutfile
          diff_length = lengthfile - lengthdir
     ;     ;print, 'diff_length = ', diff_length
     progressBar->Update, (1)*50
            IF (diff_length EQ 6) OR (diff_length EQ 7) THEN BEGIN
              IF (diff_length EQ 6) THEN BEGIN
              filter_number = strmid(myoutfile, lengthdir, 6)
      ;        ;print, 'filter_number = ', filter_number
              myoutfilenew = myoutdir + 'B+W_' + filter_number
       ;       ;print, 'myoutfile = ', myoutfilenew
              scaled_image = (!D.table_size - 1)* (FLOAT(myimg_0 - min(myimg_0))/FLOAT(max(myimg_0) - min(myimg_0)))
              write_png, myoutfilenew, scaled_image
              ENDIF
              IF (diff_length EQ 7) THEN BEGIN
              filter_number = strmid(myoutfile, lengthdir, 7)
        ;      ;print, 'filter_number = ', filter_number
              myoutfile_lwac = myoutdir + 'B+W_' + filter_number
         ;     ;print, 'myoutfile = ', myoutfilenew
              scaled_image = (!D.table_size - 1)* (FLOAT(myimg_0 - min(myimg_0))/FLOAT(max(myimg_0) - min(myimg_0)))
              write_png, myoutfile_lwac, scaled_image
              ENDIF
              
            ENDIF ELSE BEGIN
            message = DIALOG_MESSAGE("THIS IMAGE HAS NOT BEEN SAVED. Please make sure that your images follow the naming convention of 'f1.png', 'f2.png', etc and that no image name is greater than f99", /INFORMATION)
            ENDELSE
          ENDIF
          progressBar->Destroy
          Obj_Destroy, progressBar 
        ENDIF
        IF (SIZE(file_select_lwac, /N_ELEMENTS) NE 3 AND SIZE(file_select_lwac, /N_ELEMENTS) NE 1) THEN BEGIN
        Message = DIALOG_MESSAGE("SELECT 1 LWAC FILE, OR 3 LWAC FILES",/INFORMATION)
        ENDIF
      ENDIF ELSE BEGIN
      Message = DIALOG_MESSAGE("NO LWAC DATA SELECTED",/INFORMATION)
    ENDELSE
            ENDIF
            CD, myoutdir_lwac
            print, 'myoutfile_lwac = ', myoutfile_lwac
            ENDIF
            IF file_select_lwac[0] NE '' OR count_L NE '' OR L_or_R EQ 'LWAC' THEN BEGIN

            
            image = read_png(myoutfile_lwac)
            XROI, image, r, g, b, $ REGIONS_IN = regions, $
            REGIONS_OUT = regions, $
            ROI_SELECT_COLOR = roi_select_color, $
           ; ROI_GEOMETRY = geometry, $
            ROI_COLOR = roi_color, REJECTED = rejected, /BLOCK
            OBJ_DESTROY, rejected
            ENDIF
            ENDIF ELSE BEGIN
            Message = DIALOG_MESSAGE("NO PDS RAD DATA OR AUPE DATA SELECTED",/INFORMATION)
            ENDELSE
          END
          
          
        'Select_ROI_PDS_RWAC' : BEGIN
        
        ;; work on this bit!! still needs help, bottom needs to be put in if statement? maybe something that will change in first if. file needs to be changed.
            IF (file[0] NE '') THEN BEGIN
            file_select_rwac = ''
            ;CD, myoutdir
            number_of_files=size(file,/dimension)
            myoutfile_rwac = myoutfile
            print, 'myoutfile = ', myoutfile
            myoutdir_rwac = myoutdir
            IF L_or_R EQ 'LWAC' THEN BEGIN
            IF count_R NE '' THEN BEGIN
            myoutfile_rwac = myoutfile_O
            dir_length = strpos(myoutfile_O, '\', /reverse_search)
            myoutdir_rwac = strmid(myoutfile_O, 0, dir_length + 1)
            print, 'myoutdir_rwac = ', myoutdir_rwac
            ENDIF
            
            IF count_R EQ '' THEN BEGIN
            CD, myoutdir
            file_select_rwac = DIALOG_PICKFILE(/MULTIPLE_FILES, /READ, $
            FILTER='*.png', /FIX_FILTER)
            IF (file_select_rwac[0] NE '') THEN BEGIN
                IF (SIZE(file_select_rwac, /N_ELEMENTS) EQ 3 OR SIZE(file_select_rwac, /N_ELEMENTS) EQ 1) THEN BEGIN
    dir_length = strpos(file_select_rwac[0], '\', /reverse_search)
    myoutdir = strmid(file_select_rwac[0], 0, dir_length + 1)
    
    progressBar = Obj_New("SHOWPROGRESS")
    progressBar->Start

      IF (SIZE(file_select_rwac, /N_ELEMENTS) EQ 3) THEN BEGIN
     
      myimg_0 = read_png(file_select_rwac[0]) 
      myimg_1 = read_png(file_select_rwac[1]) 
      myimg_2 = read_png(file_select_rwac[2])
       
      s=size(myimg_0,/dimension)
   ;   ;print, 's = ', s
      RGB=intarr(3,s[0],s[1])
      New_RGB=fltarr(3,s[0],s[1]) ;Used in 'save_image' event below.
    
      RGB[0,*,*]= myimg_0
      RGB[1,*,*]= myimg_1
      RGB[2,*,*]= myimg_2
      
    ;  ;print, 'myoutdir =', myoutdir
       ;The following string manipulation functions extract which filtered images have been selected,
      ;and create a filename with these values.
      length_all = make_array(1, 3, /INTEGER)
      length0 = strlen(file_select_rwac[0])
      length1 = strlen(file_select_rwac[1])
      length2 = strlen(file_select_rwac[2])
      length_all [0] = length0
      length_all [1] = length1
      length_all [2] = length2
      max_length = max(length_all)
     ; ;print, 'max length = ', max_length
        IF (max_length EQ (dir_length + 8) OR max_length EQ (dir_length + 7)) THEN BEGIN
          IF (max_length EQ (dir_length + 8)) THEN BEGIN
            IF length0 EQ max_length THEN BEGIN
            filter_no_1 = strmid(file_select_rwac[0], (max_length - 7), 3)
            ENDIF ELSE BEGIN
            filter_no_1 = strmid(file_select_rwac[0], (max_length - 7), 2)
            ENDELSE
            IF length1 EQ max_length THEN BEGIN
            filter_no_2 = strmid(file_select_rwac[1], (max_length - 7), 3)
            ENDIF ELSE BEGIN
            filter_no_2 = strmid(file_select_rwac[1], (max_length - 7), 2)
            ENDELSE
            IF length2 EQ max_length THEN BEGIN
            filter_no_3 = strmid(file_select_rwac[2], (max_length - 7), 3)
            ENDIF ELSE BEGIN
            filter_no_3 = strmid(file_select_rwac[2], (max_length - 7), 2)
            ENDELSE
            ENDIF
            IF (max_length EQ (dir_length + 7)) THEN BEGIN
            filter_no_1 = strmid(file_select_rwac[0], (max_length - 6), 2)
            filter_no_2 = strmid(file_select_rwac[1], (max_length - 6), 2)
            filter_no_3 = strmid(file_select_rwac[2], (max_length - 6), 2)  
            ENDIF 
      progressBar->Update, (1)*50
            IF (max_length EQ (dir_length + 8)) THEN BEGIN
              IF length0 EQ length1 AND length1 EQ length2 THEN BEGIN
              myoutfile = 'RGB-   -   -   .png'
              strput, myoutfile, filter_no_1, 4
              strput, myoutfile, filter_no_2, 8
              strput, myoutfile, filter_no_3, 12
              ENDIF
              IF length0 GT length1 AND length0 GT length2 THEN BEGIN
              myoutfile = 'RGB-   -  -  .png'
              strput, myoutfile, filter_no_1, 4
              strput, myoutfile, filter_no_2, 8
              strput, myoutfile, filter_no_3, 11
              ENDIF
              IF length1 GT length0 AND length1 GT length2 THEN BEGIN
              myoutfile = 'RGB-  -   -  .png'
              strput, myoutfile, filter_no_1, 4
              strput, myoutfile, filter_no_2, 7
              strput, myoutfile, filter_no_3, 11
              ENDIF
              IF length2 GT length0 AND length2 GT length1 THEN BEGIN
              myoutfile = 'RGB-  -  -   .png'
              strput, myoutfile, filter_no_1, 4
              strput, myoutfile, filter_no_2, 7
              strput, myoutfile, filter_no_3, 10
              ENDIF
              IF length0 EQ length1 AND length0 GT length2 THEN BEGIN
              myoutfile = 'RGB-   -   -  .png'
              strput, myoutfile, filter_no_1, 4
              strput, myoutfile, filter_no_2, 8
              strput, myoutfile, filter_no_3, 12    
              ENDIF
              IF length1 EQ length2 AND length1 GT length0 THEN BEGIN
              myoutfile = 'RGB-  -   -   .png'
              strput, myoutfile, filter_no_1, 4
              strput, myoutfile, filter_no_2, 7
              strput, myoutfile, filter_no_3, 11
              ENDIF
              IF length0 EQ length2 AND length0 GT length1 THEN BEGIN
              myoutfile = 'RGB-   -  -   .png'
              strput, myoutfile, filter_no_1, 4
              strput, myoutfile, filter_no_2, 8
              strput, myoutfile, filter_no_3, 11
              ENDIF
            ENDIF
              IF (max_length EQ (dir_length + 7)) THEN BEGIN
              myoutfile = 'RGB-  -  -  .png'
              strput, myoutfile, filter_no_1, 4
              strput, myoutfile, filter_no_2, 7
              strput, myoutfile, filter_no_3, 10
              ENDIF
          dir_length = strpos(file_select_rwac[0], '\', /reverse_search)
     ;     ;print, 'dir_length =', dir_length
          myoutdir = strmid(file_select_rwac[0], 0, dir_length + 1)
     ;     ;print, 'myoutdir =', myoutdir
          myoutfile_rwac = myoutdir + myoutfile
     ;     ;print, 'myoutfile = ', myoutfile
          ;Scale the RGB image data from 16-bit to 8-bit. This can be read by the XROI widget.
          New_RGB[2,*,*] = (!D.table_size - 1)* (FLOAT(RGB[0,*,*] - min(RGB[0,*,*]))/FLOAT(max(RGB[0,*,*]) - min(RGB[0,*,*])))
          New_RGB[1,*,*] = (!D.table_size - 1)* (FLOAT(RGB[1,*,*] - min(RGB[1,*,*]))/FLOAT(max(RGB[1,*,*]) - min(RGB[1,*,*])))
          New_RGB[0,*,*] = (!D.table_size - 1)* (FLOAT(RGB[2,*,*] - min(RGB[2,*,*]))/FLOAT(max(RGB[2,*,*]) - min(RGB[2,*,*])))
          
          write_png, myoutfile_rwac, new_RGB
          print, 'myoutfile_rwac = ', myoutfile_rwac
          
  ;        ;print, 'myoutfile new = ', myoutfile
          ENDIF ELSE BEGIN
          message = DIALOG_MESSAGE("THIS IMAGE HAS NOT BEEN SAVED. Please make sure that your images follow the naming convention of 'f1.png', 'f2.png', etc and that no image name is greater than f99", /INFORMATION)
          ENDELSE
        ENDIF
          IF (SIZE(file_select_rwac, /N_ELEMENTS) EQ 1) THEN BEGIN
          myimg_0 = read_png(file_select_rwac[0]) ; /silent) ;/noscale)
          dir_length = strpos(file_select_rwac[0], '\', /reverse_search)
     ;     ;print, 'dir_length =', dir_length
          myoutdir = strmid(file_select_rwac[0], 0, dir_length + 1)
          
      ;    ;print, 'myoutdir =', myoutdir
          length = strlen(file_select_rwac[0])
          s1=size(file_select_rwac,/dimension)
          ;Create a new string array for the output file path and assign 'myinfile'.
     ;     ;print, 'myoutdir = ', myoutdir
          lengthdir = strlen(myoutdir)
  ;        ;print, 'lengthdir = ', lengthdir
          myoutfile = strarr(1)       
          myoutfile[*] = file_select_rwac[0]
          lengthfile = strlen(myoutfile)
          
   ;       ;print, 'lengthfile = ', lengthfile
    ;      ;print, 'myoutfile = ', myoutfile
          diff_length = lengthfile - lengthdir
     ;     ;print, 'diff_length = ', diff_length
     progressBar->Update, (1)*50
            IF (diff_length EQ 6) OR (diff_length EQ 7) THEN BEGIN
              IF (diff_length EQ 6) THEN BEGIN
              filter_number = strmid(myoutfile, lengthdir, 6)
      ;        ;print, 'filter_number = ', filter_number
              myoutfilenew = myoutdir + 'B+W_' + filter_number
       ;       ;print, 'myoutfile = ', myoutfilenew
              scaled_image = (!D.table_size - 1)* (FLOAT(myimg_0 - min(myimg_0))/FLOAT(max(myimg_0) - min(myimg_0)))
              write_png, myoutfilenew, scaled_image
              ENDIF
              IF (diff_length EQ 7) THEN BEGIN
              filter_number = strmid(myoutfile, lengthdir, 7)
        ;      ;print, 'filter_number = ', filter_number
              myoutfile_rwac = myoutdir + 'B+W_' + filter_number
         ;     ;print, 'myoutfile = ', myoutfilenew
              scaled_image = (!D.table_size - 1)* (FLOAT(myimg_0 - min(myimg_0))/FLOAT(max(myimg_0) - min(myimg_0)))
              write_png, myoutfile_rwac, scaled_image
              ENDIF
              
            ENDIF ELSE BEGIN
            message = DIALOG_MESSAGE("THIS IMAGE HAS NOT BEEN SAVED. Please make sure that your images follow the naming convention of 'f1.png', 'f2.png', etc and that no image name is greater than f99", /INFORMATION)
            ENDELSE
          ENDIF
          progressBar->Destroy
          Obj_Destroy, progressBar 
        ENDIF
        IF (SIZE(file_select_rwac, /N_ELEMENTS) NE 3 AND SIZE(file_select_rwac, /N_ELEMENTS) NE 1) THEN BEGIN
        Message = DIALOG_MESSAGE("SELECT 1 RWAC FILE, OR 3 RWAC FILES",/INFORMATION)
        ENDIF
      ENDIF ELSE BEGIN
      Message = DIALOG_MESSAGE("NO RWAC DATA SELECTED",/INFORMATION)
    ENDELSE
            ENDIF
            CD, myoutdir_rwac
            print, 'myoutfile_rwac = ', myoutfile_rwac
            ENDIF
            IF file_select_rwac[0] NE '' OR count_R NE '' OR L_or_R EQ 'RWAC' THEN BEGIN
            image = read_png(myoutfile_rwac)
            XROI, image, r, g, b, $ REGIONS_IN = regions_RWAC, $
            REGIONS_OUT = regions_RWAC, $
            ROI_SELECT_COLOR = roi_select_color, $
           ; ROI_GEOMETRY = geometry, $
            ROI_COLOR = roi_color, REJECTED = rejected, /BLOCK
            OBJ_DESTROY, rejected
            ENDIF
            ENDIF ELSE BEGIN
            Message = DIALOG_MESSAGE("NO PDS RAD DATA OR AUPE DATA SELECTED",/INFORMATION)
            ENDELSE
          END
            
          'restore_ROI_PDS' : BEGIN
          IF (file[0] NE '') THEN BEGIN
          IF rstar_check EQ 1 THEN BEGIN
          L_or_R = ''
          count_l = ''
          ENDIF
          myoutdir_lwac = myoutdir
          IF L_or_R EQ 'RWAC' AND count_L NE '' THEN BEGIN
          dir_length = strpos(myoutfile_O, '\', /reverse_search)
          myoutdir_lwac = strmid(myoutfile_O, 0, dir_length + 1)
          ENDIF
          CD, (myoutdir_lwac)          
          ;path_in = !DIR+'/examples/data'
          savefile = DIALOG_PICKFILE(/MULTIPLE_FILES, /READ, $
          FILTER='*.sav', /FIX_FILTER)
          ;print, 'savefile = ', savefile
            IF (savefile[0] NE '') THEN BEGIN
            number_of_files=size(file,/dimension)
            myoutfile_lwac = myoutfile
            IF L_or_R EQ 'RWAC' THEN BEGIN
            IF count_L NE '' THEN BEGIN
            myoutfile_lwac = myoutfile_O
            ENDIF
            ENDIF
            image = read_png(myoutfile_lwac)
            RESTORE, savefile, RESTORED_OBJECTS = myRoi
            XROI, image, REGIONS_IN = myRoi, $
            ROI_GEOMETRY = statistics, $
            REJECTED = rejected, /BLOCK
            roi_test = 1
            ;print, 'statistics = ', statistics
            ENDIF ELSE BEGIN
            Message = DIALOG_MESSAGE("Please select a .sav ROI file",/INFORMATION)
            ENDELSE
            ENDIF ELSE BEGIN
            Message = DIALOG_MESSAGE("Please select either PDS or AUPE data first",/INFORMATION)
            ENDELSE            
          END
          
          'restore_ROI_PDS_RWAC' : BEGIN
          IF (file[0] NE '') THEN BEGIN
          myoutdir_rwac = myoutdir
          IF L_or_R EQ 'LWAC' AND count_R NE '' THEN BEGIN
          dir_length = strpos(myoutfile_O, '\', /reverse_search)
          myoutdir_rwac = strmid(myoutfile_O, 0, dir_length + 1)
          ENDIF
          CD, (myoutdir_rwac)
          savefile_RWAC = DIALOG_PICKFILE(/MULTIPLE_FILES, /READ, $
          FILTER='*.sav', /FIX_FILTER)
          ;print, 'savefile = ', savefile
            IF (savefile_RWAC[0] NE '') THEN BEGIN
            number_of_files=size(file,/dimension)
            myoutfile_rwac = myoutfile
            print, 'myoutfile = ', myoutfile
            IF L_or_R EQ 'LWAC' THEN BEGIN
            IF count_R NE '' THEN BEGIN
            myoutfile_rwac = myoutfile_O
            ENDIF
            ENDIF
            image = read_png(myoutfile_rwac)
            RESTORE, savefile_RWAC, RESTORED_OBJECTS = myRoi_RWAC
            XROI, image, REGIONS_IN = myRoi_RWAC, $
            ROI_GEOMETRY = statistics, $
            REJECTED = rejected, /BLOCK
            roi_test = 1
            ;print, 'statistics = ', statistics
            ENDIF ELSE BEGIN
            Message = DIALOG_MESSAGE("Please select a .sav ROI file",/INFORMATION)
            ENDELSE
            ENDIF ELSE BEGIN
            Message = DIALOG_MESSAGE("Please select either PDS or AUPE data first",/INFORMATION)
            ENDELSE            
          END          
          
          
          'Choose_LWAC_Rstar' : BEGIN
IF roi_test EQ 1 THEN BEGIN
myoutdir_lwac = myoutdir
IF L_or_R EQ 'LWAC' AND count_L NE '' THEN BEGIN
dir_length = strpos(myoutfile_O, '\', /reverse_search)
myoutdir_lwac = strmid(myoutfile_O, 0, dir_length + 1)
ENDIF
CD, (myoutdir_lwac)
file3 = DIALOG_PICKFILE(/MULTIPLE_FILES, /READ, $
FILTER = '*.rst', /FIX_FILTER)
IF (file3[0] NE '') THEN BEGIN
number_of_files = size(file3,/dimension)
averagearray = make_array(2,number_of_files, /STRING)
x_filters = make_array(1, number_of_files, /INTEGER)
y_reflectance = make_array(1, number_of_files, /FLOAT)
y_standard_deviation = make_array(number_of_files, /FLOAT)
length_whole = strlen(file3[0]) 
dir_length = strpos(file3[0], '\', /reverse_search)
;print, 'dir_length =', dir_length
length_rstar = length_whole - dir_length
myoutdir = strmid(file3[0], 0, dir_length + 1)
cd, myoutdir
file_size = FLTARR(2)
OPENR, 5, 'file_dimensions.dat'
READF,5,file_size
width = file_size(0)
height = file_size(1)
CLOSE,5
IF number_of_files EQ 6 THEN BEGIN
progressBar = Obj_New("SHOWPROGRESS")
progressBar->Start
FOR i=0, (number_of_files[0] - 1) DO BEGIN
file_name_string_0 = strmid(file3[i],dir_length + 1 , length_rstar)
print, 'file_name_string_0 = ', file_name_string_0
file_0 = FLTARR(file_size(0), file_size(1))
OPENR, 2, file_name_string_0
READF,2,file_0
CLOSE,2
file_wavelength_roi = FLTARR(number_of_files)
OPENR, 3, 'all_wavelengths.dat'
READF,3,file_wavelength_roi
CLOSE,3
RESTORE, savefile, RESTORED_OBJECTS = myRoi
XROI, file_0, REGIONS_IN = myRoi, GROUP = death, $
STATISTICS = statistics, $
REJECTED = rejected, $
/BLOCK
average = statistics.(3)
standard_deviation = statistics.(4)
Filtername = file_wavelength_roi(i)
print, 'filtername = ', filtername
y_standard_deviation [i] = standard_deviation
averagearray [0,i] = Filtername
averagearray [1,i] = average  
x_filters [i] = filtername
y_reflectance [i] = average     
progressBar->Update, (i+1)*10
ENDFOR
progressBar->Destroy
Obj_Destroy, progressBar
ENDIF ELSE BEGIN
Message = DIALOG_MESSAGE("Please select 6 R* (.Rst) files",/INFORMATION)
ENDELSE 
ENDIF ELSE BEGIN
Message = DIALOG_MESSAGE("Please select 6 R* (.Rst) files",/INFORMATION)
ENDELSE
ENDIF ELSE BEGIN
Message = DIALOG_MESSAGE("Please select a ROI saved file first",/INFORMATION)
ENDELSE  
          END
          
          
          'Choose_RWAC_Rstar' : BEGIN
          IF roi_test EQ 1 THEN BEGIN
          myoutdir_rwac = myoutdir
          IF L_or_R EQ 'LWAC' AND count_R NE '' THEN BEGIN
          dir_length = strpos(myoutfile_O, '\', /reverse_search)
          myoutdir_rwac = strmid(myoutfile_O, 0, dir_length + 1)
          ENDIF
          CD, (myoutdir_rwac)
file5 = DIALOG_PICKFILE(/MULTIPLE_FILES, /READ, $
FILTER = '*.rst', /FIX_FILTER)
IF (file5[0] NE '') THEN BEGIN
number_of_files = size(file5,/dimension)
averagearray_R = make_array(2,number_of_files, /STRING)
x_filters_R = make_array(1, number_of_files, /INTEGER)
y_reflectance_R = make_array(1, number_of_files, /FLOAT)
y_standard_deviation_R = make_array(number_of_files, /FLOAT)
length_whole = strlen(file5[0]) 
dir_length = strpos(file5[0], '\', /reverse_search)
;print, 'dir_length =', dir_length
length_rstar = length_whole - dir_length
myoutdir = strmid(file5[0], 0, dir_length + 1)
print, 'myoutdir = ', myoutdir
cd, myoutdir
file_size = FLTARR(2)
OPENR, 5, 'file_dimensions.dat'
READF,5,file_size
width = file_size(0)
height = file_size(1)
CLOSE,5
IF number_of_files EQ 6 THEN BEGIN
progressBar = Obj_New("SHOWPROGRESS")
progressBar->Start
FOR i=0, (number_of_files[0] - 1) DO BEGIN
file_name_string_0 = strmid(file5[i],dir_length + 1 , length_rstar)
print, 'file_name_string_0 = ', file_name_string_0
file_0 = FLTARR(file_size(0), file_size(1))
OPENR, 2, file_name_string_0
READF,2,file_0
CLOSE,2
file_wavelength_roi = FLTARR(number_of_files)
OPENR, 3, 'all_wavelengths.dat'
READF,3,file_wavelength_roi
CLOSE,3
RESTORE, savefile_RWAC, RESTORED_OBJECTS = myRoi_RWAC
XROI, file_0, REGIONS_IN = myRoi_RWAC, GROUP = death, $
STATISTICS = statistics, $
REJECTED = rejected, $
/BLOCK
average = statistics.(3)
standard_deviation = statistics.(4)
Filtername = file_wavelength_roi(i)
print, 'filtername = ', filtername
y_standard_deviation_R [i] = standard_deviation
averagearray_R [0,i] = Filtername
averagearray_R [1,i] = average  
x_filters_R [i] = filtername
y_reflectance_R [i] = average     
progressBar->Update, (i+1)*10
ENDFOR
progressBar->Destroy
Obj_Destroy, progressBar
ENDIF ELSE BEGIN
Message = DIALOG_MESSAGE("Please select 6 R* (.Rst) files",/INFORMATION)
ENDELSE 
ENDIF ELSE BEGIN
Message = DIALOG_MESSAGE("Please select 6 R* (.Rst) files",/INFORMATION)
ENDELSE
ENDIF ELSE BEGIN
Message = DIALOG_MESSAGE("Please select a ROI saved file first",/INFORMATION)
ENDELSE 
          END
          
          'create_graph' : BEGIN
IF roi_test EQ 1 THEN BEGIN
IF rstar_check EQ 1 THEN BEGIN
path_in = !DIR+'/examples/data'
file3 = DIALOG_PICKFILE(PATH=path_in, /MULTIPLE_FILES, /READ, $
FILTER = '*.rst', /FIX_FILTER)
IF (file3[0] NE '') THEN BEGIN
number_of_files = size(file3,/dimension)
averagearray = make_array(2,number_of_files, /STRING)
x_filters = make_array(1, number_of_files, /INTEGER)
y_reflectance = make_array(1, number_of_files, /FLOAT)
y_standard_deviation = make_array(number_of_files, /FLOAT)
length_whole = strlen(file3[0]) 
dir_length = strpos(file3[0], '\', /reverse_search)
;print, 'dir_length =', dir_length
length_rstar = length_whole - dir_length
myoutdir = strmid(file3[0], 0, dir_length + 1)
cd, myoutdir
file_size = FLTARR(2)
OPENR, 5, 'file_dimensions.dat'
READF,5,file_size
width = file_size(0)
height = file_size(1)
;print, 'width  = ', width 
;print, 'height = ', height
;print, 'file_size = ', file_size
CLOSE,5
IF number_of_files EQ 6 THEN BEGIN
progressBar = Obj_New("SHOWPROGRESS")
progressBar->Start
FOR i=0, (number_of_files[0] - 1) DO BEGIN
;file_po = read_png(file3[i])
;;print, 'file_po[0:10]', file_po[0:10]
;'file_0 = file_po
;;print, 'file_0[0:10]', file_0[0:10]
;;print, 'point 1'
file_name_string_0 = strmid(file3[i],dir_length + 1 , length_rstar)
print, 'file_name_string_0 = ', file_name_string_0
file_0 = FLTARR(file_size(0), file_size(1))
OPENR, 2, file_name_string_0
READF,2,file_0
CLOSE,2
file_wavelength_roi = FLTARR(number_of_files)
OPENR, 3, 'all_wavelengths.dat'
READF,3,file_wavelength_roi
;print, 'file_wavelength roi = ', file_wavelength_roi
CLOSE,3
;o = strcompress(STRING(i), /REMOVE_ALL)
;print, 'size of fileeee = ', size(filename)
;print, 'size of fileeee 2222 = ', size(file_0)
RESTORE, savefile, RESTORED_OBJECTS = myRoi
XROI, file_0, REGIONS_IN = myRoi, GROUP = death, $
STATISTICS = statistics, $
REJECTED = rejected, $
/BLOCK
;print, 'statistics = ', statistics
average = statistics.(3)
standard_deviation = statistics.(4)
;print, 'average', average
Filtername = file_wavelength_roi(i)
print, 'filtername = ', filtername
;print, 'point 2'
;print, 'Filter name=', Filtername
;print, 'i =', i
y_standard_deviation [i] = standard_deviation
averagearray [0,i] = Filtername
averagearray [1,i] = average
;print, 'average array = ', averagearray
;print, 'filtername =', filtername
;;print, 'filter', filter  
x_filters [i] = filtername
y_reflectance [i] = average   
;print, 'x_filters', x_filters
;print, 'y_reflectance', y_reflectance
;print, 'average array =', averagearray  
progressBar->Update, (i+1)*10
ENDFOR
progressBar->Destroy
Obj_Destroy, progressBar
ENDIF ELSE BEGIN
Message = DIALOG_MESSAGE("Please select 6 R* (.Rst) files",/INFORMATION)
ENDELSE 
ENDIF ELSE BEGIN
Message = DIALOG_MESSAGE("Please select 6 R* (.Rst) files",/INFORMATION)
ENDELSE
ENDIF

IF (file3[0] NE '') OR (file5[0] NE '') THEN BEGIN
IF number_of_files EQ 6 THEN BEGIN

IF rstar_check EQ 0 OR rstar_check EQ 1 THEN BEGIN
IF rstar_check EQ 0 THEN BEGIN
IF stereo EQ 'LWAC' THEN BEGIN
x_before = x_filters
y_before = y_reflectance
the_standard_deviation = y_standard_deviation
ENDIF
IF stereo EQ 'RWAC' THEN BEGIN
x_before = x_filters_R
y_before = y_reflectance_R
the_standard_deviation = y_standard_deviation_R
ENDIF
IF stereo EQ 'Both' THEN BEGIN
print, 'x_filters_R = ', x_filters_R
print, 'x_filters = ', x_filters
s1 = size(x_filters, /DIMENSIONS)
s2 = size(x_filters_R, /DIMENSIONS)
print, 's1[1] = ', s1[1]
print, 's2[1] = ', s2[1]
arraysize = s1[1] + s2[1]
print, 'arraysize = ', arraysize
x_before = make_array(arraysize)
FOR i=0, (s1[1] - 1) DO BEGIN
x_before [i] = x_filters [i]
ENDFOR
FOR i=0, (s2[1] - 1) DO BEGIN
x_before [s2[1] + i] = x_filters_R [i]
ENDFOR
print, 'x_before = ', x_before
s3 = size(y_reflectance, /DIMENSIONS)
s4 = size(y_reflectance_R, /DIMENSIONS)
print, 's3[1] = ', s3[1]
print, 's4[1] = ', s4[1]
arraysize = s3[1] + s4[1]
print, 'arraysize = ', arraysize
y_before = make_array(arraysize)
FOR i=0, (s3[1] - 1) DO BEGIN
y_before [i] = y_reflectance [i]
ENDFOR
FOR i=0, (s4[1] - 1) DO BEGIN
y_before [s4[1] + i] = y_reflectance_R [i]
ENDFOR 
s5 = (size(y_standard_deviation, /DIMENSIONS))
s6 = (size(y_standard_deviation_R, /DIMENSIONS))
print, 's5[0] = ', s5[0]
print, 's6[0] = ', s6[0]
;print, 's5[1] = ', s5[1]
arraysize = s5[0] + s6[0]
print, 'arraysize = ', arraysize
the_standard_deviation = make_array(arraysize)
FOR i=0, (s5[0] - 1) DO BEGIN
the_standard_deviation [i] = y_standard_deviation [i]
ENDFOR
FOR i=0, (s6[0] - 1) DO BEGIN
the_standard_deviation [s6[0] + i] = y_standard_deviation_R [i]
ENDFOR 
print, 'x_before = ', x_before
print, 'y_before = ', y_before
ENDIF
ENDIF
 ;print, 'x_filters = ', x_filters
 IF rstar_check EQ 1 THEN BEGIN
 ;! minimum = min(x_filters)
 ;!maximum = max(x_filters)
 ;!range = (maximum - minimum) + 1
  ;!x_array = findgen(range) + minimum
  
 x_before = REVERSE(x_filters, 2)
 y_before = REVERSE(y_reflectance, 2)
 ENDIF
  x_x = x_before
  y = y_before
  ;t = x_array
  ;cubicspline = SPLINE(x_x,y,t) ;/double);, sigma)
  ;print, 'size of spline = ', size(cubicspline)
 ; window, 1
;!!  plot, x_x, y, psym=-7, $
 ; xrange=[420,765],  /xstyle, /ystyle, $ ;yrange=[0,0.12],
;!!  xtitle='Wavelength (nanometers)', $
 ;!! ytitle='Reflectance', $
 ;!! title='Reflectance of calibration target'
 ; print, 'y_standard_deviation = ', y_standard_deviation
 IF rstar_check EQ 0 THEN BEGIN
  plottt = ERRORPLOT(x_x, y, the_standard_deviation, $
      xtitle='Wavelength (nanometers)', $
  ytitle='Reflectance', $
  title='Reflectance of a region of interest');, $
  ENDIF
  IF rstar_check EQ 1 THEN BEGIN
  window, 1
  plot, x_x, y, psym=-7, $
  xrange=[420,765],  /xstyle, /ystyle, $ ;yrange=[0,0.12],
  xtitle='Wavelength (nanometers)', $
  ytitle='Reflectance', $
  title='Reflectance of a region of interest'
  ENDIF
  ;LINESTYLE = 6, $
  ; /OVERPLOT)
;  oplot, x_x, yeplot, linestyle = 6
;working on thissssssssss

;progressBar->Destroy
;Obj_Destroy, progressBar
ENDIF ELSE BEGIN
Message = DIALOG_MESSAGE("Please select a ROI saved file first",/INFORMATION)
ENDELSE  
ENDIF
ENDIF
ENDIF
          END
          
          
        'calculate_n' : BEGIN
          ;select roi - from centroid 3 pixels each way
          ;get array of coords
          ;get array of pixel values for each image
          ;put spline across pixel array
          ;calc Y
          ;average
          ;calculate Y
          ;save n
          
                          IF (file[0] NE '') THEN BEGIN
;below I'm making an array of the pixel values
;     
  path_in = !DIR+'/examples/data'
  file_n = DIALOG_PICKFILE(PATH=path_in, /MULTIPLE_FILES, /READ, $
  FILTER='*.rst', /FIX_FILTER)

    IF (file_n[0] NE '') THEN BEGIN
    number_of_files=size(file_n,/dimension)
    IF number_of_files EQ 6 THEN BEGIN
   
CD, myoutdir    
print, 'myoutdir  =  ',myoutdir 
coord_array_x = FLTARR(25)
OPENR, 4, 'White_region_coordinates_x.wrc'
READF,4,coord_array_x
CLOSE,4
coord_array_y = FLTARR(25)
OPENR, 4, 'White_region_coordinates_y.wrc'
READF,4,coord_array_y
CLOSE,4
    
    image_1 = make_array(25)
    image_2 = make_array(25)
    image_3 = make_array(25) 
    image_4 = make_array(25)
    image_5 = make_array(25)
    image_6 = make_array(25)
    
    
    rstar_1 = read_csv(file_n[0])
    rstar_2 = read_csv(file_n[1])
    rstar_3 = read_csv(file_n[2])
    rstar_4 = read_csv(file_n[3])
    rstar_5 = read_csv(file_n[4])
    rstar_6 = read_csv(file_n[5])
    
    ;print, typename(rstar_1) ;this is a structure.....7
  ;  help, rstar_1, /structures
  ;  print, 'size = ', size(rstar_1)
 ;;   test =  rstar_1.(0) 
  ;;  test2 = test[0]
   ;; print, 'test2 = ', test2
    ;;print, 'file_n[0] = ', file_n[0] ;(THIS IS CLUMSY BUT IT WORKS!!!!)
   ; s = {rstar_1,tag:0}
   ; print, 's = ', s
    
    FOREACH element, coord_array_x, index DO BEGIN
    
 ;;   image_1(index) = rstar_1[coord_array_x(index), coord_array_y(index)]; @@@@@@@!!!!!!!!!
    ;t = read_csv(file_n[0])
    ;1
    x = coord_array_x(index)
    y = coord_array_y(index)
    test_1 =  rstar_1.(x) 
    test2_1 = test_1[y]
  ;  print, 'test2 = ', test2
   ; print, 'file_n[0] = ', file_n[0]
   ;2
    x = coord_array_x(index)
    y = coord_array_y(index)
    test_2 =  rstar_2.(x) 
    test2_2 = test_2[y]
   ;3
    x = coord_array_x(index)
    y = coord_array_y(index)
    test_3 =  rstar_3.(x) 
    test2_3 = test_3[y]  
   ;4
    x = coord_array_x(index)
    y = coord_array_y(index)
    test_4 =  rstar_4.(x) 
    test2_4 = test_4[y]
   ;5
    x = coord_array_x(index)
    y = coord_array_y(index)
    test_5 =  rstar_5.(x) 
    test2_5 = test_5[y]
   ;6
    x = coord_array_x(index)
    y = coord_array_y(index)
    test_6 =  rstar_6.(x) 
    test2_6 = test_6[y]  
    print, 'x = ', x
    print, 'y = ', y    
    
    image_1[index] = test2_1
    image_2[index] = test2_2
    image_3[index] = test2_3
    image_4[index] = test2_4
    image_5[index] = test2_5
    image_6[index] = test2_6
    

    
    ENDFOREACH
    
    print, 'image_1 = ', image_1
    print, 'image_2 = ', image_2
    print, 'image_3 = ', image_3
    print, 'image_4 = ', image_4
    print, 'image_5 = ', image_5
    print, 'image_6 = ', image_6

;print, 'image_1 = ', image_1

cd, myoutdir
file_wavelength = FLTARR(number_of_files)
OPENR, 4, 'all_wavelengths.dat'
READF,4,file_wavelength
CLOSE,4
minimum = min(file_wavelength)
maximum = max(file_wavelength)
range = (maximum - minimum) + 1

IF rstar_check EQ 1 THEN BEGIN
x_array = findgen(441) + 390 
spline_array = make_array(25, 441)
ENDIF

IF rstar_check EQ 0 THEN BEGIN
x_array = findgen(range) + minimum
spline_array = make_array(25, range)
ENDIF

IF rstar_check EQ 1 THEN BEGIN
x = REVERSE(file_wavelength)
ENDIF
IF rstar_check EQ 0 THEN BEGIN
x = file_wavelength
ENDIF



foreach element, image_1, index do begin
  y = make_array(number_of_files)
  IF rstar_check EQ 1 THEN BEGIN
  y[5] = image_1[index]
  y[4] = image_2[index]
  y[3] = image_3[index]
  y[2] = image_4[index]
  y[1] = image_5[index]
  y[0] = image_6[index]

  ENDIF
  IF rstar_check EQ 0 THEN BEGIN
  y[0] = image_1[index]
  y[1] = image_2[index]
  y[2] = image_3[index]
  y[3] = image_4[index]
  y[4] = image_5[index]
  y[5] = image_6[index]
  ENDIF

  cubic_spline = SPLINE(x, y, x_array)
 ; print, 'index = ', index
 ; print, 'size of cubic spline = ', SIZE(cubic_spline);, /DIMENSIONS)
  spline_array[index,*] = cubic_spline

;print, 'size of spline array = ', size(spline_array)


endforeach

print, 'y = ', y
print, 'first lot of elements = ', spline_array(0)

IF rstar_check EQ 1 THEN BEGIN
wavelength_array = indgen((((441)/5) + 1))/0.2 + 390


cd, img_dir

    y_bar = READ_SYLK("StdObsFuncs.slk", /ARRAY, /COLMAJOR, $
    STARTROW = (11), STARTCOL = 2, NCOLS = 1, NROWS = (89))


    t = indgen(441)+ 390
    m = 441
          ENDIF

          IF rstar_check EQ 0 THEN BEGIN 
          
  wavelength_array = indgen((((maximum - minimum)/5) + 1))/0.2 + minimum
  
  CD,img_dir

    y_bar = READ_SYLK("StdObsFuncs.slk", /ARRAY, /COLMAJOR, $
    STARTROW = (((minimum - 360)/5)+5), STARTCOL = 2, NCOLS = 1, NROWS = (((maximum - minimum)/5) + 1)) ; /USEDOUBLES) ;/USELONGS)

    t = indgen((maximum - minimum) + 1)+ minimum

          ENDIF

 cubic_y_bar = spline(wavelength_array, y_bar, t)
 

   size_ybar = size((cubic_y_bar), /DIMENSIONS)

print, 'cubic_y_bar = ', cubic_y_bar[0:10]
size_spline = size(spline_array)

w = size_spline(1)
h = size_spline(2)
d = size_spline(3)


IF rstar_check EQ 0 THEN BEGIN
m = d
ENDIF

Y = make_array(25)

;spline_subset = spline_array(0:((w*h)-1))
;  CD, myoutdir
print, 'spline_array[0:10] = ', spline_array[0:10]
Robbie_var = 0
bigger_array_y = make_array(25, range)
foreach element, spline_array, index do begin
 ; count = -1

  ;little_array = index

  ;(size_ybar)

 ; WHILE (little_array + (w*h)) LT (index + (w*h*m)) OR (little_array + (w*h)) EQ (index + (w*h*m)) DO BEGIN
;print, 'index = ', index
index_2 = rnd(index/25)
;print, 'index_2 = ', index_2
  ;count = count + 1
 ; print, 'element = ', element
 ; print, 'cubic_y_bar[index_2] = ', cubic_y_bar[index_2]
  print, 'element * cubic_y_bar[index_2] = ', element * cubic_y_bar[index_2]
  bigger_array_y[index] = (element * cubic_y_bar[index_2])
  print, 'bigger_array_y[index] = ', bigger_array_y[index]
 ; little_array = little_array + (w*h)
 ; ENDWHILE
 Robbie_var = Robbie_var + 1
 endforeach
 print, 'Robbie_var = ', Robbie_var 
 print, 'bigger_array = ', bigger_array_y
 transpose_array = transpose(bigger_array_y)
 FOR i=0, (24) DO BEGIN
  total_y = TOTAL(transpose_array[i])
  Y(i) = total_y
  ENDFOR
  print, 'Y = ', Y

  

n = MEAN(Y)
print, 'n = ', n



ENDIF
    ENDIF ELSE BEGIN
     Message = DIALOG_MESSAGE("Please select all 6 narrowband image files",/INFORMATION)
    ENDELSE
    
        
       ; p = image_1(geo_1, geo_2)    
       ; print, p
        ENDIF ELSE BEGIN
        Message = DIALOG_MESSAGE("NO AUPE DATA SELECTED",/INFORMATION)
        ENDELSE
          
          END
          
          'restore_n' : BEGIN
          END
                    'cleanip' : BEGIN
                    print, 'hello Robbie'
          END
          
          'save_xyy' : BEGIN
        save_little_x = myoutdir + 'lowercase_x.csv'
        save_little_y = myoutdir + 'lowercase_y.csv'
        save_big_y = myoutdir + 'capital_y.csv'
        Write_csv, save_little_x, little_x
        Write_csv, save_little_y, little_y
        Write_csv, save_big_y, Y
          
          END
          
          'restore_xyy' : BEGIN
          cd, myoutdir
file_size = FLTARR(2)
OPENR, 3, 'file_dimensions.dat'
READF,3,file_size
width = file_size(0)
height = file_size(1)
CLOSE,3
little_x = FLTARR(width, height)
OPENR, 4, 'lowercase_x.csv'
READF,4,little_x
CLOSE,4
little_y = FLTARR(width, height)
OPENR, 5, 'lowercase_y.csv'
READF,5, little_y
CLOSE,5
Y = FLTARR(width, height)
OPENR, 6, 'capital_y.csv'
READF,6,Y
CLOSE,6
          END
          
          
 'exit' : WIDGET_CONTROL, ev.top, /DESTROY
 ENDCASE
 END
 


PRO RCIPP
; Initialise 'myinfile' to an empty string array.
COMMON block_names, second_base, third_base, fourth_base, fifth_base, sixth_base, seventh_base, eighth_base, ninth_base, tenth_base, eleventh_base, draw_generate, draw_histoplot, drawroigraph, draw, drawoffset, drawloadpds, drawloadpds_2, drawcie, drawexp_1, drawexp_2, drawexp_3, drawexp_4, file, mistake, Stereo, bgroup2, myoutfile, myoutdir, savefile, number_of_files_stats, filter_number, y_reflectance, stat_test, radiance_per_sec, Rstar_check, minimum, maximum, spline_array, X, Y, Z, little_x, little_y, mistake2, mistake3, file2, roi_test, file4, rstar_spline_test, CIE_test, CIE_little_xyz_test, directory, count_slp_2, count_slp_1, count_exp, mistake6, mistake5, mistake4, file_R, file_E, aupe_check, mistake7, file3, file5, x_filters_R, y_reflectance_R, y_standard_deviation_R, x_filters, y_standard_deviation, number_of_files, L_or_R, myoutfile_O, count_L, count_R, savefile_RWAC, img_dir, mistake_gen, mistake_srgb, n, white_data, neutral_44_data, neutral_70_data, neutral_1_05_data, black_data, blue_data, green_data, red_data, yellow_data, white, neutral_44, neutral_70, neutral_1_05, black, blue, green, red, yellow, colour_array
white = 0
neutral_44 = 0
neutral_70 = 0
neutral_1_05 = 0
black = 0
blue = 0
green = 0
red = 0
yellow = 0
mistake2 = 0
n = ''
mistake3 = 0
savefile = ''
mistake_gen = 0
mistake_srgb = 0
roi_test = 0
CIE_test = 0
CIE_little_xyz_test = 0
rstar_spline_test = 0
radiance_per_sec = ''
file = strarr(1)
file[0] = ''
file2 = ''
file3 = ''
file4 = ''
file5 = ''
file_R = ''
file_E = ''
directory = ''
main_base = WIDGET_BASE(TITLE='AUPE RGB',/COLUMN, XSIZE=860, YSIZE=633)
second_base = WIDGET_BASE(GROUP_LEADER=main_base,/COLUMN, XSIZE=330, YSIZE=300, /ALIGN_TOP)
third_base = WIDGET_BASE(GROUP_LEADER=main_base,/COLUMN, XSIZE=330, YSIZE=300, /ALIGN_TOP)
fourth_base = WIDGET_BASE(GROUP_LEADER=main_base,/COLUMN, XSIZE=330, YSIZE=275, /ALIGN_TOP)
fifth_base = WIDGET_BASE(GROUP_LEADER=main_base,/COLUMN, XSIZE=330, YSIZE=275, /ALIGN_TOP)
sixth_base = WIDGET_BASE(GROUP_LEADER=main_base,/COLUMN, XSIZE=330, YSIZE=275, /ALIGN_TOP)
seventh_base = WIDGET_BASE(GROUP_LEADER=main_base,/COLUMN, XSIZE=330, YSIZE=275, /ALIGN_TOP) 
eighth_base = WIDGET_BASE(GROUP_LEADER=main_base,/COLUMN, XSIZE=330, YSIZE=275, /ALIGN_TOP)
ninth_base = WIDGET_BASE(GROUP_LEADER=main_base,/COLUMN, XSIZE=330, YSIZE=275, /ALIGN_TOP)
tenth_base = WIDGET_BASE(GROUP_LEADER=main_base,/COLUMN, XSIZE=330, YSIZE=275, /ALIGN_TOP)
eleventh_base = WIDGET_BASE(GROUP_LEADER=main_base,/COLUMN, XSIZE=700, YSIZE=485, /ALIGN_TOP)
;draw2 = WIDGET_DRAW(main_base, XSIZE=100, YSIZE=20, YOFFSET = 100)
;logo_base = WIDGET_BASE(main_base, /COLUMN, /FRAME, /ALIGN_LEFT, XSIZE=100, YSIZE=100)

row1 = WIDGET_BASE(main_base, /ROW, /FRAME, YSIZE=50)
row2 = WIDGET_BASE(main_base, /ROW, /FRAME, YSIZE=458)
row3 = WIDGET_BASE(main_base, /ROW, /FRAME, YSIZE=106)

row_second_base1 = WIDGET_BASE(second_base, /ROW, /FRAME, YSIZE=50)
row_second_base2 = WIDGET_BASE(second_base, /ROW, /FRAME, YSIZE=238)

row_third_base1 = WIDGET_BASE(third_base, /ROW, /FRAME, YSIZE=50)
row_third_base2 = WIDGET_BASE(third_base, /ROW, /ALIGN_CENTER, YSIZE=50)
row_third_base5 = WIDGET_BASE(third_base, /ROW, YSIZE=50)
row_third_base3 = WIDGET_BASE(third_base, /ROW, /ALIGN_CENTER, YSIZE=80)
row_third_base4 = WIDGET_BASE(third_base, /ROW, /ALIGN_CENTER, YSIZE=70)


row_fourth_base1 = WIDGET_BASE(fourth_base, /ROW, /FRAME, YSIZE=50)
row_fourth_base2 = WIDGET_BASE(fourth_base, /ROW, /FRAME, YSIZE=213)

row_fifth_base1 = WIDGET_BASE(fifth_base, /ROW, /FRAME, YSIZE=50)
row_fifth_base2 = WIDGET_BASE(fifth_base, /ROW, /FRAME, YSIZE=213)

row_sixth_base1 = WIDGET_BASE(sixth_base, /ROW, /FRAME, YSIZE=50)
row_sixth_base2 = WIDGET_BASE(sixth_base, /ROW, /FRAME, YSIZE=213)

row_seventh_base1 = WIDGET_BASE(seventh_base, /ROW, /FRAME, YSIZE=50)
row_seventh_base2 = WIDGET_BASE(seventh_base, /ROW, /FRAME, YSIZE=213)

row_eighth_base1 = WIDGET_BASE(eighth_base, /ROW, /FRAME, YSIZE=50)
row_eighth_base2 = WIDGET_BASE(eighth_base, /ROW, /FRAME, YSIZE=213)

row_ninth_base1 = WIDGET_BASE(ninth_base, /ROW, /FRAME, YSIZE=50)
row_ninth_base2 = WIDGET_BASE(ninth_base, /ROW, /FRAME, YSIZE=213)

row_tenth_base1 = WIDGET_BASE(tenth_base, /ROW, /FRAME, YSIZE=50)
row_tenth_base2 = WIDGET_BASE(tenth_base, /ROW, /FRAME, YSIZE=213)

row_eleventh_base1 = WIDGET_BASE(eleventh_base, /ROW, /FRAME, YSIZE=400)
row_eleventh_base2 = WIDGET_BASE(eleventh_base, /ROW, /FRAME, YSIZE=70)

drawtitle = WIDGET_DRAW(row1, XSIZE=847, YSIZE=44)
drawbottom = WIDGET_DRAW(row3, XSIZE=847, YSIZE=100)

drawoffset = WIDGET_DRAW(row_second_base1, XSIZE=317, YSIZE=44)
drawloadpds = WIDGET_DRAW(row_third_base1, XSIZE=317, YSIZE=44)
drawloadpds_2 = WIDGET_DRAW(row_third_base5, XSIZE=317, YSIZE=44)
drawcie = WIDGET_DRAW(row_fourth_base1, XSIZE=317, YSIZE=44)
drawexp_1 = WIDGET_DRAW(row_fifth_base1, XSIZE=317, YSIZE=44)
drawexp_2 = WIDGET_DRAW(row_sixth_base1, XSIZE=317, YSIZE=44)
drawexp_3 = WIDGET_DRAW(row_seventh_base1, XSIZE=317, YSIZE=44)
drawexp_4 = WIDGET_DRAW(row_eighth_base1, XSIZE=317, YSIZE=44)
drawroigraph = WIDGET_DRAW(row_ninth_base1, XSIZE=317, YSIZE=44)
draw_generate = WIDGET_DRAW(row_tenth_base1, XSIZE=317, YSIZE=44)
draw_histoplot = WIDGET_DRAW(row_eleventh_base1, XSIZE=694, YSIZE=394)

button_base = WIDGET_BASE(row2, /COLUMN, /FRAME, /ALIGN_LEFT, XSIZE=194)
button_base_row = WIDGET_BASE(button_base, /COLUMN)
button_base2 = WIDGET_BASE(row2, /COLUMN, /FRAME, /ALIGN_LEFT, XSIZE=194)
button_base_row2 = WIDGET_BASE(button_base2, /COLUMN)
button_base_offset_slope = WIDGET_BASE(row_second_base2, /COLUMN, /FRAME, /ALIGN_TOP, XSIZE=184)
button_base_pds = WIDGET_BASE(row_third_base2, /COLUMN, /ALIGN_LEFT, XSIZE=220)
button_base_pds_2 = WIDGET_BASE(row_third_base3, /COLUMN, /ALIGN_LEFT, XSIZE=110)
button_base_pds_3 = WIDGET_BASE(row_third_base3, /COLUMN, /ALIGN_LEFT, XSIZE=110)
button_base_pds_4 = WIDGET_BASE(row_third_base4, /COLUMN, /ALIGN_LEFT, XSIZE=220)
button_base_cie = WIDGET_BASE(row_fourth_base2, /COLUMN, /FRAME, /ALIGN_LEFT, XSIZE=190)
button_base_exp_1 = WIDGET_BASE(row_fifth_base2, /COLUMN, /FRAME, /ALIGN_LEFT, XSIZE=184)
button_base_exp_2 = WIDGET_BASE(row_sixth_base2, /COLUMN, /FRAME, /ALIGN_LEFT, XSIZE=184)
button_base_exp_3 = WIDGET_BASE(row_seventh_base2, /COLUMN, /FRAME, /ALIGN_LEFT, XSIZE=184)
button_base_exp_4 = WIDGET_BASE(row_eighth_base2, /COLUMN, /FRAME, /ALIGN_LEFT, XSIZE=184)
button_base_roi = WIDGET_BASE(row_ninth_base2, /COLUMN, /FRAME, /ALIGN_LEFT, XSIZE=184)
button_base_sRGB = WIDGET_BASE(row_tenth_base2, /COLUMN, /FRAME, /ALIGN_TOP, XSIZE=184)
button_base_histoplot = WIDGET_BASE(row_eleventh_base2, /COLUMN, /FRAME, /ALIGN_TOP, XSIZE=684) 

sub_button_base = WIDGET_BASE(button_base2, /ROW)

sub_button_base_cie = WIDGET_BASE(button_base_cie, /ROW)

sub_sub_button_base = WIDGET_BASE(sub_button_base_cie, /COLUMN)
sub_sub_button_base2 = WIDGET_BASE(sub_button_base_cie, /COLUMN)

rawinput = WIDGET_DRAW(button_base_row, XSIZE=184, YSIZE=50)
aupsdinput = WIDGET_DRAW(button_base_row2, XSIZE=184, YSIZE=50)

;result = WIDGET_TEXT(main_base, SCR_XSIZE=150, SCR_YSIZE=200, VALUE="For a colour image, please pick your images in the order: RGB", /WRAP, /SCROLL)
button = widget_button(button_base, TOOLTIP = 'this is a placeholder button', VALUE='Co-register Images', $
UVALUE='Co_register_images')
button = widget_button(button_base, VALUE='Flat field correction', $
UVALUE='Flat_Field_correction')
button = widget_button(button_base, VALUE='Camera response correction', $
UVALUE='Camera_response_correction')
button = widget_button(button_base, VALUE='Generate RGB image', $
UVALUE='Generate_RGB_image')
button = widget_button(button_base, VALUE='Radiance Scaling Factor and Offset', $
UVALUE='Calculate_offset_and_slope')
button = widget_button(sub_button_base, VALUE='Load AUPE data', $
UVALUE='Generate_RGB_image')
button = widget_button(sub_button_base, VALUE='Load PDS data', $
UVALUE='Load_PDS_data')
button = widget_button(button_base2, VALUE='Generate R*', $
UVALUE='Generate_RStar')
button = widget_button(button_base2, VALUE='Create ROI graph', $
UVALUE='Create_ROI_graph')
button = widget_button(button_base2, VALUE='Generate CIE data', $
UVALUE='Generate_CIE_data_second')
button = widget_button(button_base2, VALUE='CIE to sRGB', $
UVALUE='CIE_to_sRGB_second')
button = widget_button(button_base2, VALUE='Exit', $
UVALUE='exit')
button = widget_button(button_base_offset_slope, VALUE='Select ROI', $
UVALUE='Select_ROI_AUPE')
button = widget_button(button_base_offset_slope, VALUE='Restore ROI', $
UVALUE='Restore_ROI_AUPE')
button = widget_button(button_base_offset_slope, VALUE='Get Statistics', $
UVALUE='Get_Stats')
button = widget_button(button_base_offset_slope, VALUE='Create Histogram', $ 
UVALUE='create_histogram')
values = ['white','neutral (.44)', 'neutral (.70)', 'neutral (1.05)', 'black', 'blue', 'green', 'red', 'yellow']
bgroup3 = CW_BGROUP(button_base_histoplot, values, /ROW, LABEL_TOP='Untick any colours you do not want to include:', /NONEXCLUSIVE,SET_VALUE=[1,1,1,1,1,1,1,1,1], UVALUE='roi_colours', /RETURN_ID)
button = widget_button(button_base_offset_slope, VALUE='Calculate Radiance/sec', $
UVALUE='Calculate_Radiance_per_sec')
values = ['LWAC', 'RWAC']
bgroup2 = CW_BGROUP(button_base_offset_slope, values, /ROW, LABEL_TOP='Left or Right Camera?', /EXCLUSIVE, UVALUE='left_or_right', /RETURN_ID)
button = widget_button(button_base_offset_slope, VALUE='Radiance Scaling Factor and Offset', $
UVALUE='Calculate_offset_and_slope_small')
button = widget_button(button_base_offset_slope, VALUE='exit', $
UVALUE='exit')
values = ['LWAC', 'RWAC', 'Both']
bgroup2 = CW_BGROUP(button_base_pds, values, /ROW, LABEL_TOP='Do you want to create graph for:', /EXCLUSIVE, UVALUE='left_or_right_or_both', /RETURN_ID)
button = widget_button(button_base_pds_2, VALUE='Select ROI', $
UVALUE='Select_ROI_PDS')
button = widget_button(button_base_pds_3, VALUE='Select ROI', $
UVALUE='Select_ROI_PDS_RWAC') ;;;!! does not exist yet
button = widget_button(button_base_pds_2, VALUE='Restore ROI', $
UVALUE='restore_ROI_PDS')
button = widget_button(button_base_pds_3, VALUE='Restore ROI', $
UVALUE='restore_ROI_PDS_RWAC') ;;;!! does not exist yet
button = widget_button(button_base_pds_2, VALUE='Choose LWAC R*', $
UVALUE='Choose_LWAC_Rstar')
button = widget_button(button_base_pds_3, VALUE='Choose RWAC R*', $
UVALUE='Choose_RWAC_Rstar') 
button = widget_button(button_base_pds_4, VALUE='Create Graph', $
UVALUE='create_graph')
button = widget_button(button_base_pds_4, VALUE='exit', $
UVALUE='exit')
;button = widget_button(sub_sub_button_base, VALUE='Select White ROI', $
;UVALUE='select_white_roi')
;button = widget_button(sub_sub_button_base, VALUE='Restore White ROI', $
;UVALUE='restore_white_roi')
;button = widget_button(sub_sub_button_base2, VALUE='     Restore N     ', $
;UVALUE='restore_n')
button = widget_button(sub_button_base_cie, VALUE='   Calculate N   ', $
UVALUE='calculate_n')
button = widget_button(sub_button_base_cie, VALUE='   Restore N   ', $
UVALUE='restore_n')
button = widget_button(button_base_cie, VALUE='Generate CIE Data', $
UVALUE='Generate_CIE_data')
button = widget_button(button_base_cie, VALUE='Save xyY', $
UVALUE='save_xyy')
button = widget_button(button_base_cie, VALUE='exit', $
UVALUE='exit')
button = widget_button(button_base_exp_1, VALUE='Get Exposure Values', $
UVALUE='Get_exposure_values')
button = widget_button(button_base_exp_1, VALUE='Radiance Scaling Factor Values', $
UVALUE='Get_Radiance_Scaling_Factor_Values')
button = widget_button(button_base_exp_1, VALUE='Generate R* for LWAC', $
UVALUE='Generate_RStar')
button = widget_button(button_base_exp_1, VALUE='Generate R* for RWAC', $
UVALUE='Generate_RStar_RWAC')
button = widget_button(button_base_exp_1, VALUE='exit', $
UVALUE='exit')
button = widget_button(button_base_exp_2, VALUE='Radiance Scaling Factor Values', $
UVALUE='Get_Radiance_Scaling_Factor_Values')
button = widget_button(button_base_exp_2, VALUE='Generate R* for LWAC', $
UVALUE='Generate_RStar')
button = widget_button(button_base_exp_2, VALUE='Generate R* for RWAC', $
UVALUE='Generate_RStar_RWAC')
button = widget_button(button_base_exp_2, VALUE='exit', $
UVALUE='exit')
button = widget_button(button_base_exp_3, VALUE='Get Exposure Values', $
UVALUE='Get_exposure_values')
button = widget_button(button_base_exp_3, VALUE='Generate R* for LWAC', $
UVALUE='Generate_RStar')
button = widget_button(button_base_exp_3, VALUE='Generate R* for RWAC', $
UVALUE='Generate_RStar_RWAC')
button = widget_button(button_base_exp_3, VALUE='exit', $
UVALUE='exit')
button = widget_button(button_base_exp_4, VALUE='Generate R* for LWAC', $
UVALUE='Generate_RStar')
button = widget_button(button_base_exp_4, VALUE='Generate R* for RWAC', $
UVALUE='Generate_RStar_RWAC')
button = widget_button(button_base_exp_4, VALUE='exit', $
UVALUE='exit')
button = widget_button(button_base_roi, VALUE='Select ROI', $
UVALUE='Select_ROI_PDS')
button = widget_button(button_base_roi, VALUE='Restore ROI', $
UVALUE='restore_ROI_PDS')
button = widget_button(button_base_roi, VALUE='Create Graph', $
UVALUE='create_graph')
button = widget_button(button_base_roi, VALUE='exit', $
UVALUE='exit')
button = widget_button(button_base_srgb, VALUE='Restore x,y,Y', $
UVALUE='restore_xyy')
button = widget_button(button_base_srgb, VALUE='CIE to sRGB', $
UVALUE='CIE_to_sRGB')
button = widget_button(button_base_srgb, VALUE='exit', $
UVALUE='exit')
draw = WIDGET_DRAW(row2, XSIZE=450, YSIZE=450)
WIDGET_CONTROL, main_base, /REALIZE
WIDGET_CONTROL, drawtitle, GET_VALUE=drawtitleid
WIDGET_CONTROL, main_base, SET_UVALUE=drawtitleid
WSET, drawtitleid
CD, C=c
;PRINT, c
img_dir = c  ;;;;;;!!! ADD THIS BEFORE BUILDING PROJECT!!!!!!  ;;;;;  + '\resources'
cd, img_dir
;image = read_png('titleforwidget.png')
restore, 'titleforwidget.sav'
TVSCL, image, true=1
WIDGET_CONTROL, drawbottom, GET_VALUE=drawbottomid
WIDGET_CONTROL, main_base, SET_UVALUE=drawbottomid
WSET, drawbottomid
restore, 'bottomlogosnew.sav'
TVSCL, image2, true=1
WIDGET_CONTROL, rawinput, GET_VALUE=rawinputid
WIDGET_CONTROL, main_base, SET_UVALUE=rawinputid
WSET, rawinputid
restore, 'rawdatawidget.sav'
TVSCL, image3, true=1
WIDGET_CONTROL, aupsdinput, GET_VALUE=aupsdinputid
WIDGET_CONTROL, main_base, SET_UVALUE=aupsdinputid
WSET, aupsdinputid
restore, 'pdsandauwidget.sav'
TVSCL, image4, true=1

WIDGET_CONTROL, bgroup2, GET_VALUE=bgroup2id
WIDGET_CONTROL, main_base, SET_UVALUE=bgroup2id
WIDGET_CONTROL, bgroup3, SET_UVALUE=bgroup3id
WIDGET_CONTROL, main_base, SET_UVALUE=bgroup3id
WIDGET_CONTROL, draw, GET_VALUE=drawid
WIDGET_CONTROL, main_base, SET_UVALUE=drawid
XMANAGER, 'RCIPP', main_base, /NO_BLOCK
XMANAGER, 'RCIPP', fourth_base, /NO_BLOCK
XMANAGER, 'RCIPP', third_base, /NO_BLOCK
XMANAGER, 'RCIPP', second_base, /NO_BLOCK, cleanup = cleanip
XMANAGER, 'RCIPP', fifth_base, /NO_BLOCK
XMANAGER, 'RCIPP', sixth_base, /NO_BLOCK
XMANAGER, 'RCIPP', seventh_base, /NO_BLOCK
XMANAGER, 'RCIPP', eighth_base, /NO_BLOCK
XMANAGER, 'RCIPP', ninth_base, /NO_BLOCK
XMANAGER, 'RCIPP', tenth_base, /NO_BLOCK
XMANAGER, 'RCIPP', eleventh_base, /NO_BLOCK

;ENDIF ELSE BEGIN
;  Message = DIALOG_MESSAGE("Please close the program, start it again and select one of the image files provided (e.g. 'complete_widget\necessary_files\bottomlogos.png')",/INFORMATION)
;ENDELSE
END