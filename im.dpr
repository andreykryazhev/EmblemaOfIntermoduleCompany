program im;

uses
  Windows, Messages, OpenGL;

{$R *.res}

type
  PEllipsePoints = ^TEllipsePoints;
  TEllipsePoints = array of array [0..3] of TGLArrayf3;

  TRuningMode = (rmRun, rmRunPreview, rmRunSettings);

 const
  class_name = 'E8F43000-3C99-4DC3-8B3F-E8E5BA268A79';
  window_style_full_screen = longword(2264924160);
  scale_koef = 1/7; // коэффициент масштабирования букв
  main_width = 0.25; // ширина модели
  detal_level = 100; // уровень детализации эллипсов
  // идентификаторы таймеров
  id_timer_1 = 100;
  id_timer_2 = 101;
  // текст и заголовок для сообщения об отсутствии параметров
  str_text = 'Sorry. This screensaver have no params.';
  str_caption = 'Intermodule screensaver';

var
  wnd_class: TWndClass; // структура класса окна
  handle_window: HWnd; // идентификатор окна
  Msg: TMsg; // структура сообщения
  winDC: HDC; // описатель контекста устройства
  winGL: HGLRC; // и контекста воспроизведения OpenGL
  // массивы точек для объёмных эллипсов
  ellipse_1_points, ellipse_2_points, ellipse_3_points: TEllipsePoints;
  quad_sphere: GLUQuadricObj; // сфера (будущая "точка над i")
  rotate_X, rotate_Y, rotate_Z: integer; // углы для поворота сцены
  move_counter: integer;

  // массив точек буквы "m"
  map_m_1_points: array [0..36] of TGLArrayf3 = ((-3.25, -2.5, 0), (-3, 1, 0),
  (-3.1, 1.5, 0), (-3.25, 1.75, 0), (-3.5, 1.7, 0), (-3.5, 2, 0), (-2, 2.75, 0),
  (-2, 2.25, 0), (-1.5, 2.5, 0), (-1, 2.75, 0), (-0.5, 2.75, 0), (0, 2.5, 0),
  (0.5, 2.25, 0), (1, 2.5, 0), (1.5, 2.75, 0), (2, 2.75, 0), (2.5, 2.5, 0),
  (3, 2, 0), (2.75, -1.5, 0), (3, -1.75, 0), (3.25, -1.75, 0), (3.2, -2.25, 0),
  (2.5, -2.5, 0), (2.5, -2.5, 0), (2, -2.25, 0), (1.75, -2, 0), (2, 1.5, 0),
  (1.5, 2, 0), (1, 1.75, 0), (0.5, 1.5, 0), (0.25, -2.5, 0), (-0.75, -2.5, 0),
  (-0.5, 1.5, 0), (-1, 2, 0), (-1.5, 1.75, 0), (-2, 1.5, 0), (-2.25, -2.5, 0));

  // массив точек буквы "i"
  map_i_1_points: array [0..16] of TGLArrayf3 = ((1, 1.5, 0), (0, -1.5, 0),
  (0, -2, 0), (0.2, -2.25, 0), (0.5, -2.5, 0), (1, -2.5, 0), (0.9, -2.75, 0),
  (0, -3, 0), (-0.5, -2.9, 0), (-1, -2.5, 0), (-1.1, -2, 0), (-1, -1.5, 0),
  (-0.5, 0, 0), (-0.4, 0.5, 0), (-0.5, 0.75, 0), (-1.2, 1, 0), (-1, 1.5, 0));

  // массивы для букв с отличными z-координатами точек
  map_m_2_points: array [0..36] of TGLArrayf3;
  map_i_2_points: array [0..16] of TGLArrayf3;

  red, green, blue, need_red, need_green, need_blue: integer;
  param_string, str_parent_window: string;
  rect_preview: TRect;
  RuningMode: TRuningMode;
  i_parent_window, Code: integer;

procedure init_ellipse(width, a1, b1, a2, b2: single; P: PEllipsePoints);
var i: integer;
  angle, middle: single;
begin

  middle := width / 2;

  for i:=0 to detal_level-1 do
    begin
    angle := i*2*Pi/(detal_level-1);
    P^[i][0][0] := a1 * cos(angle);
    P^[i][0][1] := b1 * sin(angle);
    P^[i][0][2] := middle;
    //
    P^[i][1][0] := P^[i][0][0];
    P^[i][1][1] := P^[i][0][1];
    P^[i][1][2] := -middle;
    //
    P^[i][2][0] := a2 * cos(angle);
    P^[i][2][1] := b2 * sin(angle);
    P^[i][2][2] := middle;
    //
    P^[i][3][0] := P^[i][2][0];
    P^[i][3][1] := P^[i][2][1];
    P^[i][3][2] := -middle;
    end;

end;

procedure Init;
var i: integer;
begin

  move_counter := 0;
  red := 0; green := 0; blue := 0;

  randomize;
  need_red := random(200) + 55;
  need_green := random(200) + 55;
  need_blue := random(200) + 55;

  move(map_m_1_points, map_m_2_points, sizeof(map_m_1_points));
  move(map_i_1_points, map_i_2_points, sizeof(map_i_1_points));

  for i:=0 to 36 do
    begin
    map_m_1_points[i][2] := main_width / 2;
    map_m_2_points[i][2] := - main_width / 2
    end;
    
  for i:=0 to 16 do
    begin
    map_i_1_points[i][2] := main_width / 2;
    map_i_2_points[i][2] := -main_width / 2
    end;

  SetLength(ellipse_1_points, detal_level);
  SetLength(ellipse_2_points, detal_level);
  SetLength(ellipse_3_points, detal_level);
  init_ellipse(main_width, 2, 7/6, 1.9, 1, @ellipse_1_points);
  init_ellipse(main_width, 1.8, 0.9, 1.7, 0.8, @ellipse_2_points);
  init_ellipse(main_width, 1.6, 0.7, 0, 0, @ellipse_3_points)

end;

procedure SetGLPixelFormat(winDC: HDC);
var pfd: TPixelFormatDescriptor;
    PixelFormat: integer;
begin

  FillChar(pfd, sizeof(pfd), 0);
  pfd.dwFlags := PFD_DRAW_TO_WINDOW or PFD_SUPPORT_OPENGL or
    PFD_GENERIC_FORMAT or PFD_DOUBLEBUFFER or PFD_SWAP_COPY;
  PixelFormat := ChoosePixelFormat(winDC, @pfd);
  SetPixelFormat(winDC, PixelFormat, @pfd)

end;

procedure DrawScene;
var i: integer;
begin

  glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT);
  //glColor3f(75/255, 200/255, 75/255);
  glColor3f(red/255, green/255, blue/255);

  // последовательность поворотов всей сцены
  glPushMatrix;
    glRotate(rotate_X, 1, 0, 0);
    glRotate(-rotate_Y, 0, 1, 0);
    glRotate(rotate_Z, 0, 0, 1);

  // внешний эллипс (4 линии)
  for i:=0 to detal_level-1 do
    begin
    glBegin(GL_LINE_LOOP);
    glVertex3fv(@ellipse_1_points[i][0])
    end;
    glEnd;

  for i:=0 to detal_level-1 do
    begin
    glBegin(GL_LINE_LOOP);
    glVertex3fv(@ellipse_1_points[i][1])
    end;
    glEnd;

  for i:=0 to detal_level-1 do
    begin
    glBegin(GL_LINE_LOOP);
    glVertex3fv(@ellipse_1_points[i][2])
    end;
    glEnd;

  for i:=0 to detal_level-1 do
    begin
    glBegin(GL_LINE_LOOP);
    glVertex3fv(@ellipse_1_points[i][3])
    end;
    glEnd;

  // средний эллипс (4 линии)
  for i:=0 to detal_level-1 do
    begin
    glBegin(GL_LINE_LOOP);
    glVertex3fv(@ellipse_2_points[i][0])
    end;
    glEnd;

  for i:=0 to detal_level-1 do
    begin
    glBegin(GL_LINE_LOOP);
    glVertex3fv(@ellipse_2_points[i][1])
    end;
    glEnd;

  for i:=0 to detal_level-1 do
    begin
    glBegin(GL_LINE_LOOP);
    glVertex3fv(@ellipse_2_points[i][2])
    end;
    glEnd;

  for i:=0 to detal_level-1 do
    begin
    glBegin(GL_LINE_LOOP);
    glVertex3fv(@ellipse_2_points[i][3])
    end;
    glEnd;

  // внутренний эллипс (2 линии) 
  for i:=0 to detal_level-1 do
    begin
    glBegin(GL_LINE_LOOP);
    glVertex3fv(@ellipse_3_points[i][0])
    end;
    glEnd;

  for i:=0 to detal_level-1 do
    begin
    glBegin(GL_LINE_LOOP);
    glVertex3fv(@ellipse_3_points[i][1])
    end;
    glEnd;

  // "перемычки"
  for i:=0 to detal_level-1 do
    begin
    glBegin(GL_LINES);
    glVertex3fv(@ellipse_1_points[i][0]);
    glVertex3fv(@ellipse_1_points[i][1]);
    glVertex3fv(@ellipse_1_points[i][2]);
    glVertex3fv(@ellipse_1_points[i][3]);
    glVertex3fv(@ellipse_1_points[i][0]);
    glVertex3fv(@ellipse_1_points[i][2]);
    glVertex3fv(@ellipse_1_points[i][1]);
    glVertex3fv(@ellipse_1_points[i][3]);
    //
    glVertex3fv(@ellipse_2_points[i][0]);
    glVertex3fv(@ellipse_2_points[i][1]);
    glVertex3fv(@ellipse_2_points[i][2]);
    glVertex3fv(@ellipse_2_points[i][3]);
    glVertex3fv(@ellipse_2_points[i][0]);
    glVertex3fv(@ellipse_2_points[i][2]);
    glVertex3fv(@ellipse_2_points[i][1]);
    glVertex3fv(@ellipse_2_points[i][3]);
    //
    glVertex3fv(@ellipse_3_points[i][0]);
    glVertex3fv(@ellipse_3_points[i][1]);
    {glVertex3fv(@ellipse_3_points[i][0]);
    glVertex3fv(@ellipse_3_points[i][2]);
    glVertex3fv(@ellipse_3_points[i][1]);
    glVertex3fv(@ellipse_3_points[i][3]);}
    glEnd;
    end;

  // буквы "i" и "m"
  glScale(scale_koef, scale_koef, 1);

  glPushMatrix;
  glTranslate(2, 0.5, 0);
  glRotate(-30, 0, 0, 1);
  glBegin(GL_LINE_LOOP);
  for i:=0 to 36 do
    glVertex3fv(@map_m_1_points[i]);
  glEnd;
  glBegin(GL_LINE_LOOP);
  for i:=0 to 36 do
    glVertex3fv(@map_m_2_points[i]);
  glEnd;
  for i:=0 to 36 do
    begin
    glBegin(GL_LINES);
      glVertex3fv(@map_m_1_points[i]);
      glVertex3fv(@map_m_2_points[i]);
    glEnd;
    end;
  glPopMatrix;

  glPushMatrix;
  glTranslate(-4, -2.5, 0);
  glRotate(90, 0, 0, 1);
  glBegin(GL_LINE_LOOP);
  for i:=0 to 16 do
    glVertex3fv(@map_i_1_points[i]);
  glEnd;
  glBegin(GL_LINE_LOOP);
  for i:=0 to 16 do
    glVertex3fv(@map_i_2_points[i]);
  glEnd;
  for i:=0 to 16 do
    begin
    glBegin(GL_LINES);
      glVertex3fv(@map_i_1_points[i]);
      glVertex3fv(@map_i_2_points[i]);
    glEnd;
    end;
  glScale(1, 1, scale_koef);
  glTranslate(0.9, 2.75, 0);
  gluSphere(quad_sphere, 0.8, 12, 12);
  glPopMatrix;

  glPopMatrix;

  SwapBuffers(winDC)

end;

function WndFunction(handle_window: HWnd; Msg: Integer; Wparam: Wparam; Lparam: Lparam): LongInt; stdcall;
var paint_structure :TPAINTSTRUCT;
begin
  WndFunction := 0;
  case Msg of
    //
    WM_CREATE:
      begin
      Init;
      winDC := GetDC(handle_window);
      SetGLPixelFormat(winDC);
      winGL := wglCreateContext(winDC);
      wglMakeCurrent(winDC, winGL);
      glPolygonMode(GL_FRONT_AND_BACK, GL_LINE);
      glClearColor(0, 0, 0, 1);
      quad_sphere := gluNewQuadric;
      SetTimer(handle_window, id_timer_1, 15, nil)
      end;
    //
    WM_DESTROY:
      begin
      KillTimer(handle_window, id_timer_1);
      if RuningMode = rmRun then KillTimer(handle_window, id_timer_2);
      PostQuitMessage(0);
      gluDeleteQuadric(quad_sphere);
      wglMakeCurrent(0, 0);
      wglDeleteContext(winGL);
      ReleaseDC(handle_window, winDC);
      DeleteDC(winDC);
      Exit
      end;
    //
    WM_SIZE:
      begin
      glViewPort(0, 0, LOWORD(lParam), HIWORD(lParam));
      glMatrixMode(GL_PROJECTION);
      glLoadIdentity;
      gluPerspective(50, LOWORD(lParam)/HIWORD(lParam), 2, 7);
      glMatrixMode(GL_MODELVIEW);
      glLoadIdentity;
      glTranslate(0, 0, -4);
      InvalidateRect(handle_window, nil, false)
      end;
    //
    WM_PAINT:
      begin
      BeginPaint(handle_window, paint_structure);
      DrawScene;
      EndPaint(handle_window, paint_structure)
      end;
    //
    WM_TIMER:
      case wParam of
        id_timer_1:
          begin
          inc(rotate_X);
          inc(rotate_Y);
          inc(rotate_Z);
          if rotate_X >= 360 then rotate_X := 0;
          if rotate_Y >= 360 then rotate_Y := 0;
          if rotate_Z >= 360 then rotate_Z := 0;

          if red < need_red then inc(red) else
            if red > need_red then dec(red) else need_red := random(200) + 55;
          if green < need_green then inc(green) else
            if green > need_green then dec(green) else need_green := random(200) + 55;
          if blue < need_blue then inc(blue) else
            if blue > need_blue then dec(blue) else need_blue := random(200) + 55;

          InvalidateRect(handle_window, nil, false)
          end;
        id_timer_2: move_counter := 0;
      end;  
    WM_KEYDOWN: if RuningMode = rmRun then PostQuitMessage(0);
    //
    WM_MOUSEMOVE:
      if RuningMode = rmRun then
        begin
        inc(move_counter);
        if move_counter >= 20 then PostQuitMessage(0)
        end;
    //
  else WndFunction := DefWindowProc(handle_window, Msg, wParam, lParam);
  end;  
end;


begin

  with wnd_class do
    begin
    style := CS_PARENTDC;
    lpfnWndProc := @WndFunction;
    cbClsExtra := 0;
    cbWndExtra := 0;
    hInstance := 0;
    hIcon := 0;
    hCursor := 0;
    hbrBackground := 0;
    lpszMenuName := '';
    lpszClassName := PChar(class_name);
    hInstance := HInstance
    end;

  RegisterClass(wnd_class);

  param_string := ParamStr(1);
  if (param_string <> '') then
    begin
    if (UpCase(param_string[2]) = 'P') then RuningMode := rmRunPreview
      else if (UpCase(param_string[2]) = 'C') then  RuningMode := rmRunSettings
    end
  else RuningMode := rmRun;

  case RuningMode of
    //
    rmRunPreview:
      begin
      str_parent_window := ParamStr(2);
      val(str_parent_window, i_parent_window, Code);
      if code <> 0 then messagebox(0, 'Use SysUtils', 'Error', MB_OK or MB_ICONERROR);
      GetWindowRect(THandle(i_parent_window), rect_preview);
      handle_window := CreateWindow(PChar(class_name), nil,
        ws_Child, 0, 0, rect_preview.Right - rect_preview.Left,
        rect_preview.Bottom - rect_preview.Top, THandle(i_parent_window),
        0, HInstance, nil);
      end;
    //
    rmRun:
      begin
      handle_window := CreateWindow(PChar(class_name), nil,
        window_style_full_screen, 0, 0, 0,  0, 0, 0, HInstance, nil); //cw_UseDefault
      SetTimer(handle_window, id_timer_2, 1000, nil);
      ShowCursor(false)
      end;
    //  
    rmRunSettings:
      begin
      messagebox(0, PChar(str_text), PChar(str_caption), MB_OK or MB_ICONINFORMATION);
      Exit
      end;
  else handle_window := 0;
  end;

  ShowWindow(handle_window, SW_SHOW);
  UpdateWindow(handle_window);

  While GetMessage(Msg,0,0,0) do
    begin
    TranslateMessage(Msg);
    DispatchMessage(Msg);
    end;

end.
