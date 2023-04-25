/*
 * Copyright (C) 2023 - Ed Beroset <beroset@ieee.org>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
#ifndef SYSINFO_H
#define SYSINFO_H

#include <sys/sysinfo.h>

#include <QObject>
#include <QtQml>

class SysInfo : public QObject
{
    Q_OBJECT
    Q_PROPERTY(long uptime READ uptime NOTIFY uptimeChanged)
    Q_PROPERTY(QList<qreal> loads READ loads NOTIFY loadsChanged)
    Q_PROPERTY(unsigned long totalRam READ totalram NOTIFY totalramChanged)
    Q_PROPERTY(unsigned long freeRam READ freeram NOTIFY freeramChanged)
    Q_PROPERTY(unsigned long sharedRam READ sharedram NOTIFY sharedramChanged)
    Q_PROPERTY(unsigned long bufferRam READ bufferram NOTIFY bufferramChanged)
    Q_PROPERTY(unsigned long totalSwap READ totalswap NOTIFY totalswapChanged)
    Q_PROPERTY(unsigned long freeSwap READ freeswap NOTIFY freeswapChanged)
    Q_PROPERTY(unsigned threads READ procs NOTIFY procsChanged)
    Q_PROPERTY(unsigned long totalHigh READ totalhigh NOTIFY totalhighChanged)
    Q_PROPERTY(unsigned long freeHigh READ freehigh NOTIFY freehighChanged)
    Q_PROPERTY(unsigned memUnit READ mem_unit CONSTANT)
public:
    SysInfo(QObject *parent = nullptr);
    unsigned long uptime() const { return info.uptime; }
    QList<qreal> loads() const { return m_loads; }
    unsigned long totalram() const { return info.totalram; }
    unsigned long freeram() const { return info.freeram; }
    unsigned long sharedram() const { return info.sharedram; }
    unsigned long bufferram() const { return info.bufferram; }
    unsigned long totalswap() const { return info.totalswap; }
    unsigned long freeswap() const { return info.freeswap; }
    unsigned short procs() const { return info.procs; }
    unsigned long totalhigh() const { return info.totalhigh; }
    unsigned long freehigh() const { return info.freehigh; }
    unsigned mem_unit() const { return info.mem_unit; }

signals: 
    void uptimeChanged();
    void loadsChanged();
    void totalramChanged();
    void freeramChanged();
    void sharedramChanged();
    void bufferramChanged();
    void totalswapChanged();
    void freeswapChanged();
    void procsChanged();
    void totalhighChanged();
    void freehighChanged();

public slots:
    void refresh();

private:
    void copyLoads();

    struct sysinfo info;
    QList<qreal> m_loads;
};

#endif // SYSINFO_H
