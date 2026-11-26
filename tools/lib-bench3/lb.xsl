<?xml version="1.0" encoding="UTF-8"?>
<!-- SPDX-License-Identifier: BSD-2-Clause -->
<!-- lb.xsl: the catalog of "gen xml" as an HTML page: grouping by key, sorting, string
     functions, numbers (what the XSLT of sites does) -->
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:c="urn:x-lb:catalog" xmlns:m="urn:x-lb:meta" exclude-result-prefixes="c m">
  <xsl:output method="html" encoding="UTF-8" indent="no"/>
  <xsl:key name="by-type" match="c:item" use="@type"/>
  <xsl:template match="/c:catalog">
    <html><body>
      <p>Items: <xsl:value-of select="count(c:item)"/>, total
        <xsl:value-of select="format-number(sum(c:item/@price), '#,##0.00')"/></p>
      <xsl:for-each select="c:item[generate-id() = generate-id(key('by-type', @type)[1])]">
        <xsl:sort select="@type"/>
        <xsl:variable name="t" select="@type"/>
        <h2><xsl:value-of select="translate($t, 'abcdefghijklmnopqrstuvwxyz', 'ABCDEFGHIJKLMNOPQRSTUVWXYZ')"/></h2>
        <table>
          <xsl:for-each select="key('by-type', $t)[@price &gt; 250]">
            <xsl:sort select="@price" data-type="number" order="descending"/>
            <tr class="{concat('r', position() mod 2)}">
              <td><xsl:value-of select="@id"/></td>
              <td><xsl:value-of select="normalize-space(c:name)"/></td>
              <td><xsl:value-of select="substring(c:desc, 1, 40)"/></td>
              <td><xsl:value-of select="format-number(@price * 1.21, '0.00')"/></td>
              <td><xsl:value-of select="count(c:tags/c:tag)"/></td>
              <td><xsl:value-of select="substring-before(m:updated, 'T')"/></td>
            </tr>
          </xsl:for-each>
        </table>
      </xsl:for-each>
    </body></html>
  </xsl:template>
</xsl:stylesheet>
