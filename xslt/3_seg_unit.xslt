<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
  version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:tei="http://www.tei-c.org/ns/1.0"
  exclude-result-prefixes="tei">
  
  <xsl:output method="xml" version="1.0" encoding="UTF-8" indent="yes"/>
  <xsl:strip-space elements="*"/>
  
  <!--
    【3_seg_unit.xslt の目的】

    2_seg_multi.xslt の出力（<seg type="multi">）を受け取り、
    各 multi の内部を <seg type="unit"> に分割する。

    あわせて、拍子記号「火」「一火」について、
    unit の外側に出しつつ、火に関係する unit に subtype="ka" を付与する。

    - 対象：<seg type="multi"> の直下の子要素列。
    - 単位 <seg type="unit">：
      * 「大譜字（<g type 無し）」「引（<metamark>引</metamark>）」を基準に、
        次の大譜字・引・拍子記号などが現れる手前までを 1 unit とみなす。
    - 火・一火の扱い：
      * <metamark>火</metamark> ：unit の外側に出力し、
          その直後の unit および「火で終わる unit」には subtype="ka" を付与する。
      * <metamark>一火</metamark>：unit の外側に出力するが、subtype="ka" は付けない。
  -->
  
  <!-- [共通] 元のノード構造を保ってコピーする（デフォルト動作） -->
  <xsl:template match="@* | node()">
    <xsl:copy>
      <xsl:apply-templates select="@* | node()"/>
    </xsl:copy>
  </xsl:template>
  
  <!-- ==============================
       [1] multi 内の要素列を unit に分割
       ============================== -->
  
  <!-- <seg type="multi"> の中は必ず unit に分割する -->
  <xsl:template match="tei:seg[@type='multi']">
    <xsl:copy>
      <xsl:apply-templates select="@*"/>
      
      <xsl:variable name="first" select="*[1]"/>
      <xsl:if test="$first">
        <xsl:call-template name="unit-from">
          <xsl:with-param name="start" select="$first"/>
          <!-- 「直前に火があったかどうか」を示すフラグ（subtype="ka" 用） -->
          <xsl:with-param name="ka" select="0"/>
        </xsl:call-template>
      </xsl:if>
    </xsl:copy>
  </xsl:template>
  
  <!-- [1-1] start から順に unit / 火・一火 を出力していく -->
  <xsl:template name="unit-from">
    <xsl:param name="start"/>
    <!-- 直前に火があったかどうか（subtype="ka" 付与用フラグ） -->
    <xsl:param name="ka"/>
    
    <xsl:if test="$start">
      <xsl:choose>
        
        <!-- [A] 先頭が「火」の場合：火を unit の外に出し、次の unit に ka を付ける -->
        <xsl:when test="$start[self::tei:metamark[text()='火']]">
          <xsl:apply-templates select="$start"/>
          
          <xsl:variable name="next" select="$start/following-sibling::*[1]"/>
          <xsl:if test="$next">
            <xsl:call-template name="unit-from">
              <xsl:with-param name="start" select="$next"/>
              <!-- 火の直後の unit なので ka=1 -->
              <xsl:with-param name="ka" select="1"/>
            </xsl:call-template>
          </xsl:if>
        </xsl:when>
        
        <!-- [B] 先頭が「一火」の場合：一火を unit の外に出し、ka は付けない -->
        <xsl:when test="$start[self::tei:metamark[text()='一火']]">
          <xsl:apply-templates select="$start"/>
          
          <xsl:variable name="next" select="$start/following-sibling::*[1]"/>
          <xsl:if test="$next">
            <xsl:call-template name="unit-from">
              <xsl:with-param name="start" select="$next"/>
              <!-- 一火の後ろなので ka はリセット -->
              <xsl:with-param name="ka" select="0"/>
            </xsl:call-template>
          </xsl:if>
        </xsl:when>
        
        <!-- [C] 通常の unit を 1 つ作る -->
        <xsl:otherwise>
          <!--
            main1：
              この unit の中での「最初の大譜字 or 引」
              （<g> で @type を持たないもの／<metamark>引</metamark>）
          -->
          <xsl:variable name="main1"
            select="(
            $start[
            self::tei:g[not(@type)]
            or self::tei:metamark[text()='引']
            ]
            |
            $start/following-sibling::*[
            self::tei:g[not(@type)]
            or self::tei:metamark[text()='引']
            ][1]
            )[1]"/>
          
          <!--
            stop：
              この unit を終端させる最初の要素
              - 2つ目の大譜字（@type 無しの <g>）
              - 拍子記号：引・百・「・」・火・一火
              - 技法「かきすかし」の閉じ括弧 ┐
          -->
          <xsl:variable name="stop"
            select="$main1/following-sibling::*[
            self::tei:g[not(@type)]
            or self::tei:metamark[
            text()='引'
            or text()='百'
            or text()='・'
            or text()='火'
            or text()='一火'
            or text()='┐'
            ]
            ][1]"/>
          
          <!-- この 1 unit を出力 -->
          <seg type="unit" xmlns="http://www.tei-c.org/ns/1.0">
            <!--
              subtype="ka" を付ける条件：
                - 直前に火があり、ka=1 の場合
                - この unit の終端が「火」の場合
            -->
            <xsl:if test="$ka = 1 or $stop[self::tei:metamark[text()='火']]">
              <xsl:attribute name="subtype">ka</xsl:attribute>
            </xsl:if>
            
            <xsl:call-template name="emit-unit">
              <xsl:with-param name="node" select="$start"/>
              <xsl:with-param name="stop" select="$stop"/>
            </xsl:call-template>
          </seg>
          
          <!-- stop に応じて、次の処理を決める -->
          <xsl:if test="$stop">
            <xsl:choose>
              
              <!-- [C-1] stop が「火」の場合：火を unit の外に出し、その後ろの unit に ka を付ける -->
              <xsl:when test="$stop[self::tei:metamark[text()='火']]">
                <xsl:apply-templates select="$stop"/>
                
                <xsl:variable name="after-stop" select="$stop/following-sibling::*[1]"/>
                <xsl:if test="$after-stop">
                  <xsl:call-template name="unit-from">
                    <xsl:with-param name="start" select="$after-stop"/>
                    <xsl:with-param name="ka" select="1"/>
                  </xsl:call-template>
                </xsl:if>
              </xsl:when>
              
              <!-- [C-2] stop が「一火」の場合：一火を unit の外に出し、ka は付けない -->
              <xsl:when test="$stop[self::tei:metamark[text()='一火']]">
                <xsl:apply-templates select="$stop"/>
                
                <xsl:variable name="after-stop" select="$stop/following-sibling::*[1]"/>
                <xsl:if test="$after-stop">
                  <xsl:call-template name="unit-from">
                    <xsl:with-param name="start" select="$after-stop"/>
                    <!-- 一火の後ろなので ka=0 のまま -->
                    <xsl:with-param name="ka" select="0"/>
                  </xsl:call-template>
                </xsl:if>
              </xsl:when>
              
              <!-- [C-3] stop が 百 / ・ / 2つ目の大譜字 / 引 / ┐ の場合：
                       stop 自体を次の unit の先頭として再利用（ka はリセット） -->
              <xsl:otherwise>
                <xsl:call-template name="unit-from">
                  <xsl:with-param name="start" select="$stop"/>
                  <xsl:with-param name="ka" select="0"/>
                </xsl:call-template>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:if>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:if>
  </xsl:template>
  
  <!-- [1-2] 1 つの unit の中身を出力：start から stop の直前まで -->
  <xsl:template name="emit-unit">
    <xsl:param name="node"/>
    <xsl:param name="stop"/>
    
    <xsl:if test="$node">
      <!-- 自分自身が stop なら、この unit には含めないで終了 -->
      <xsl:if test="not($stop and generate-id($node) = generate-id($stop))">
        <xsl:apply-templates select="$node"/>
        
        <!-- 次の兄弟要素 -->
        <xsl:variable name="next" select="$node/following-sibling::*[1]"/>
        
        <!-- 次が stop でなければ、同じ unit の中身として続ける -->
        <xsl:if test="$next and not($stop and generate-id($next) = generate-id($stop))">
          <xsl:call-template name="emit-unit">
            <xsl:with-param name="node" select="$next"/>
            <xsl:with-param name="stop" select="$stop"/>
          </xsl:call-template>
        </xsl:if>
      </xsl:if>
    </xsl:if>
  </xsl:template>
  
</xsl:stylesheet>



